require_relative 'common.rb'

module PushfourAI
  class PieceRun
    attr_reader :dir, :first, :last, :length

    def initialize(x, y, dir)
      @first = [x, y]
      @last = [x, y]
      @length = 1
      @dir = dir
    end

    def add(x, y)
      return if [x, y] == @last
      @last = [x, y]
      @length += 1
    end

    def ==(other)
      return false unless other
      if other.is_a?(Array)
        return last == other
      end
      return false if dir != other.dir
      return last i== other.last
    end
  end

  class AI
    include Pushfour

    HORIZ = (1 << 0)
    VERT = (1 << 1)
    FWD_DIAG = (1 << 2)
    BACK_DIAG = (1 << 3)

    WIN = 999999999
    THRESHOLD = WIN / 10000
    LOSS = -WIN

    def initialize(id, opts = {})
      @id = id
      @poll_delay = opts[:poll_delay] || 5
      @search_depth = opts[:search_depth] || 3
    end

    def run
      thr = Thread.new do
        blacklist = []
        loop do
          game_list = Pushfour.game_list(@id) - blacklist
          puts "Finding moves for #{game_list}"
          game_list.each do |game_id|
            next if blacklist.include? game_id
            game = Pushfour.game_info(game_id, @id)
            move, score = find_move(game)
            if move
              Pushfour.send_website_move(game, move, player_id: @id, echo_params: false)
              puts "#{game_id} should move #{move} (#{score})"
            else
              blacklist << game_id
              puts "Blacklisting #{game_id} - no apparent moves available"
            end
          end

          sleep @poll_delay
        end
      end
      thr.join
    end

    def minimax(board, player, maxiplayer, depth_left)
      if maxiplayer
        return score(board, player) if depth_left == 0

        best = LOSS

        board.movable_blocks.each do |move|
          moved = board.move(move[0], move[1], player)
          mscore = score(moved, player)
          return mscore if mscore > THRESHOLD
          turn = moved.players[player] || moved.players[0]
          score = minimax(moved, turn, false, depth_left - 1)
          best = [best, score].max
        end
      else
        return -score(board, player) if depth_left == 0

        best = WIN

        board.movable_blocks.each do |move|
          moved = board.move(move[0], move[1], player)
          mscore = score(moved, player)
          return -mscore if mscore > THRESHOLD
          turn = moved.players[player] || moved.players[0]
          score = minimax(moved, turn, true, depth_left - 1)
          best = [best, score].min
        end
      end

      best
    end

    def find_move(game)
      player = game.turn
      board = game.board

      move_outcomes = {}

      board.movable_blocks.each do |move|
        moved = board.move(move[0], move[1], player)
        score = score(moved, player)
        if score > THRESHOLD
          move_outcomes = {move => {score: score, board: moved} }
          break
        end
        move_outcomes[move] = {score: score, board: moved}
      end

      move_outcomes.each do |move, outcome|
        turn = outcome[:board].players[player] || outcome[:board].players[0]
        move_outcomes[move][:score] = minimax(outcome[:board], turn, false, @search_depth - 1)
      end

      best_move = nil
      best_score = nil
      move_outcomes.each do |move, outcome|
        if !best_score || outcome[:score] > best_score
          best_move = move
          best_score = outcome[:score]
        end
      end

      [best_move, best_score]
    end

    def score(board, player)
      runs = {HORIZ => [], VERT => [], FWD_DIAG => [], BACK_DIAG => [] }

      # TODO: score only one player at a time!
      board.xy.each_with_index do |row, y|
        row.each_with_index do |block, x|
          if (block & Pushfour::PLAYER_MASK) == player
            # horizontal
            run = runs[HORIZ].delete([x-1, y]) || PieceRun.new(x, y, HORIZ)
            run.add(x, y)
            runs[HORIZ] << run

            # vertical
            run = runs[VERT].delete([x, y-1]) || PieceRun.new(x, y, VERT)
            run.add(x, y)
            runs[VERT] << run

            # backslash diag
            run = runs[FWD_DIAG].delete([x+1, y-1]) || PieceRun.new(x, y, FWD_DIAG)
            run.add(x, y)
            runs[FWD_DIAG] << run

            # forwardslash diag
            run = runs[BACK_DIAG].delete([x-1, y-1]) || PieceRun.new(x, y, BACK_DIAG)
            run.add(x, y)
            runs[BACK_DIAG] << run
          end
        end
      end

      score = 0

      runs.each do |dir, dir_runs|
        dir_runs.each do |run|
          return WIN if run.length >= 4
          run_score = 10 ** run.length
          score += run_score
        end
      end

      score
    end
  end
end
