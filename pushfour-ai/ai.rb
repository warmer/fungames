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

    WIN = 999999999999
    THRESHOLD = WIN / 1000
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
          puts "Finding moves for #{game_list}" unless game_list == []
          game_list.each do |game_id|
            next if blacklist.include? game_id
            s = Time.now
            game = Pushfour.game_info(game_id, @id)
            move, score = find_move(game)
            if move
              Pushfour.send_website_move(game, move, player_id: @id, echo_params: false)
              puts "#{game_id} should move #{move} (#{score}; took #{Time.now - s}s)"
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
      s = score(board, maxiplayer)
      if depth_left == 0 or s > THRESHOLD or s < -THRESHOLD
        return s
      end

      next_turn = board.players[player] || board.players[0]
      best = (player == maxiplayer ? LOSS : WIN)
      bmove = nil

      board.movable_blocks.each do |move|
        moved = board.move(move[0], move[1], player)
        tscore = score(board, maxiplayer)
        score = minimax(moved, next_turn, maxiplayer, depth_left - 1)
        best = (player == maxiplayer ? [best, score].max : [best, score].min)
        bmove = move if best == score
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

      if @search_depth > 1
        threads = []
        move_outcomes.each do |move, outcome|
          t = Thread.new do
            turn = outcome[:board].players[player] || outcome[:board].players[0]
            move_outcomes[move][:score] = minimax(outcome[:board], turn, player, @search_depth - 1)
          end
t.join
          threads << t
        end
        threads.each {|t| t.join}
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
      runs = Hash.new {|hash, key| hash[key] = {HORIZ => [], VERT => [], FWD_DIAG => [], BACK_DIAG => [] } }

      board.xy.each_with_index do |row, y|
        row.each_with_index do |block, x|
          if (p = block & Pushfour::PLAYER_MASK) > 0
            # horizontal
            run = runs[p][HORIZ].delete([x-1, y]) || PieceRun.new(x, y, HORIZ)
            run.add(x, y)
            runs[p][HORIZ] << run

            # vertical
            run = runs[p][VERT].delete([x, y-1]) || PieceRun.new(x, y, VERT)
            run.add(x, y)
            runs[p][VERT] << run

            # backslash diag
            run = runs[p][FWD_DIAG].delete([x+1, y-1]) || PieceRun.new(x, y, FWD_DIAG)
            run.add(x, y)
            runs[p][FWD_DIAG] << run

            # forwardslash diag
            run = runs[p][BACK_DIAG].delete([x-1, y-1]) || PieceRun.new(x, y, BACK_DIAG)
            run.add(x, y)
            runs[p][BACK_DIAG] << run
          end
        end
      end

      player_score = 0
      opp_score = 0

      runs.each do |p, pruns|
        pruns.each do |dir, dir_runs|
          dir_runs.each do |run|
            if run.length >= 4
              return WIN if player == p
              return LOSS
            end
            base_score = 0

            before = nil
            after = nil
            one_up, one_down, one_left, one_right = [nil, nil, nil, nil]
            case dir
              when HORIZ
                one_left = run.first[0] - 1 unless run.first[0] - 1 < 0
                one_right = run.last[0] + 1 unless run.last[0] + 1 == board.x
                before = board.xy[run.first[1]][one_left] if one_left
                after = board.xy[run.last[1]][one_right] if one_right
              when VERT
                one_up = run.first[1] - 1 unless run.first[1] - 1 < 0
                one_down = run.last[1] + 1 unless run.last[1] + 1 == board.y
                before = board.xy[one_up] && board.xy[one_up][run.first[0]] if one_up
                after = board.xy[one_down] && board.xy[one_down][run.last[0]] if one_down
              when FWD_DIAG
                one_left = run.last[0] - 1 unless run.last[0] - 1 < 0
                one_right = run.first[0] + 1 unless run.first[0] + 1 == board.x
                one_up = run.first[1] - 1 unless run.first[1] - 1 < 0
                one_down = run.last[1] + 1 unless run.last[1] + 1 == board.y
                before = board.xy[one_up] && board.xy[one_up][one_right] if one_up and one_right
                after = board.xy[one_down] && board.xy[one_down][one_left] if one_down and one_left
              when BACK_DIAG
                one_left = run.first[0] - 1 unless run.first[0] - 1 < 0
                one_right = run.last[0] + 1 unless run.last[0] + 1 == board.x
                one_up = run.first[1] - 1 unless run.first[1] - 1 < 0
                one_down = run.last[1] + 1 unless run.last[1] + 1 == board.y
                before = board.xy[one_up] && board.xy[one_up][one_left] if one_up and one_left
                after = board.xy[one_down] && board.xy[one_down][one_right] if one_down and one_right
            end

            if before.to_i & Pushfour::MOVABLE_MASK > 0
              base_score += 16
            elsif before.to_i & Pushfour::OPEN_MASK > 0
              base_score += 2
            end

            if after.to_i & Pushfour::MOVABLE_MASK > 0
              other_end_bonus = (base_score / 4)
              base_score += other_end_bonus*32 + 16
            elsif after.to_i & Pushfour::OPEN_MASK > 0
              other_end_bonus = (base_score / 2)
              base_score += other_end_bonus + 2
            end

            run_score = (base_score) ** run.length
            if player == p
              player_score += run_score
            else
              opp_score += run_score
            end
          end
        end
      end

      player_score - opp_score
    end
  end
end
