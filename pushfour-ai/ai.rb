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
      return last == other.last
    end
  end

  class AI
    include Pushfour

    HORIZ = (1 << 0)
    VERT = (1 << 1)
    FWD_DIAG = (1 << 2)
    BACK_DIAG = (1 << 3)

    WIN = 999999999999
    LOSS = -WIN
    THRESHOLD = WIN / 100

    RUN_SCORE = [
      0,
      1,
      8,
      512,
      32768,
      262144,
      2097152,
      16777216
    ]

    @debug = false
    @info = true

    def initialize(id, opts = {})
      @id = id
      @debug = opts[:debug]
      @info = true
      @dynamic_depth = opts[:dynamic_depth]
      @poll_delay = opts[:poll_delay] || 5
      @search_depth = opts[:search_depth] || 3
      @permaban_file = opts[:permaban_file]
    end

    def debug(line = nil)
      puts line if @debug
    end

    def info(line = nil)
      puts line if @info
    end

    def run
      thr = Thread.new do
        blacklist = []
        loop do
          game_list = Pushfour.game_list(@id) - blacklist
          info "Finding moves for #{game_list}" unless game_list == []
          game_list.each do |game_id|
            next if blacklist.include? game_id
            s = Time.now
            game = Pushfour.game_info(game_id, @id)
            move, score = find_move(game)
            if move
              Pushfour.send_website_move(game, move, player_id: @id, echo_params: false)
              info "#{game_id} should move #{move} (#{score}; took #{Time.now - s}s)"
            else
              blacklist << game_id
              info "Blacklisting #{game_id} - no apparent moves available"
            end
          end

          sleep @poll_delay
        end
      end
      thr.join
    end

    def find_move(game, force_move = nil)
      play_as = game.turn
      board = game.board

      move_outcomes = {}

      pre_best_move = nil
      pre_best_score = nil

      board.movable_blocks.each do |move|
        moved = board.move(move[0], move[1], play_as)
        if moved.game_over > 0
          info "Found win: going with #{move}"
          return [move, WIN]
        end
        score = score(moved, play_as, board.players[play_as] || board.players[0])
        move_outcomes[move] = {score: score, board: moved}

        if !pre_best_score || score > pre_best_score
          pre_best_move = move
          pre_best_score = score
        end
      end

      if force_move
        info "Ignoring all except for #{force_move}"
        debug move_outcomes.keys.inspect
        move_outcomes.reject!{|k, v| k != force_move }
        debug move_outcomes.keys.inspect
      end

      if @search_depth > 1
        depth = @search_depth - 1
        case board.movable_blocks.count
          when 1..3
            depth += 5
          when 4..5
            depth += 4
          when 6..7
            depth += 3
          when 8..9
            depth += 2
          when 10..11
            depth += 1
        end
        info "Looking #{depth} deep through #{board.movable_blocks.count} moves"
        threads = []
        move_outcomes.each do |move, outcome|
          t = Thread.new do
            read, write = IO.pipe
            pid = fork do
              read.close

              turn = outcome[:board].players[play_as] || outcome[:board].players[0]
              score = minimax(outcome[:board], turn, play_as, depth)

              Marshal.dump(score, write)
              exit!(0)
            end

            write.close
            result = read.read
            Process.wait(pid)
            raise "Finding score failed" if result.empty?
            move_outcomes[move][:score] = Marshal.load(result)
            debug "##### FINAL SCORE: #{move_outcomes[move][:score]} for #{move}"
            debug "=" * 50
            debug
          end
          t.join if @debug
          threads << t
        end
        threads.each {|t| t.join}
      end

      pre_best_move

      best_move = nil
      best_score = nil
      move_outcomes.each do |move, outcome|
        if !best_score || outcome[:score] > best_score
          best_move = move
          best_score = outcome[:score]
        end
      end

      best_move = pre_best_move if best_score == LOSS

      [best_move, best_score]
    end

    def minimax(board, current_turn, maxiplayer, depth_left)
      next_turn = board.players[current_turn] || board.players[0]
      if depth_left == 0
        s = score(board, maxiplayer, current_turn)
        debug "    ##### POPPING UP - score #{s} for #{maxiplayer} (current_turn is #{current_turn})"
        return s
      end

      find_max = current_turn == maxiplayer
      best = (find_max ? LOSS : WIN)
      bmove = nil

      debug "  ##### Find the #{find_max ? 'best' : 'worst'}"
      return 0 if board.movable_blocks.size == 0
      board.movable_blocks.each do |move|
        debug "  ##### Simulate #{move} made by by #{current_turn} (score for #{maxiplayer})"
        moved = board.move(move[0], move[1], current_turn)
        return WIN if moved.game_over == maxiplayer
        return LOSS if moved.game_over > 0
        score = minimax(moved, next_turn, maxiplayer, depth_left - 1)
        best = (find_max ? [best, score].max : [best, score].min)
        if best == score
          bmove = move
          debug "    *** NEW #{find_max ? 'best' : 'worst'} move by #{current_turn} found: #{bmove} (#{best})"
        end
      end
      debug "  ##### #{find_max ? 'best' : 'worst'} move by #{current_turn}: #{bmove} @ #{best} (#{maxiplayer})"
      best
    end

    def permaban(game_id)
      if @permaban_file
        File.open(@permaban_file, 'a+') do |f|
          f.write(game_id.to_s)
          f.write("\n")
        end
      end
    end

    def score(board, player, current_turn)
      return WIN if board.game_over == player
      return LOSS if board.game_over > 0
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

            # forwardslash diag
            run = runs[p][FWD_DIAG].delete([x+1, y-1]) || PieceRun.new(x, y, FWD_DIAG)
            run.add(x, y)
            runs[p][FWD_DIAG] << run

            # backslash diag
            run = runs[p][BACK_DIAG].delete([x-1, y-1]) || PieceRun.new(x, y, BACK_DIAG)
            run.add(x, y)
            runs[p][BACK_DIAG] << run
          end
        end
      end

      player_score = 0
      opp_score = 0

      runs.each do |p, pruns|
        next_move_bonus = (p == current_turn ? 2 : 1)
        pruns.each do |dir, dir_runs|
          dir_runs.each do |run|
            before = nil
            after = nil
            open_ends = 0
            movable_ends = 0

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
              movable_ends += 1
            elsif before.to_i & Pushfour::OPEN_MASK > 0
              open_ends += 1
            end

            if after.to_i & Pushfour::MOVABLE_MASK > 0
              movable_ends += 1
            elsif after.to_i & Pushfour::OPEN_MASK > 0
              open_ends += 1
            end

            base_score = 4 * (next_move_bonus**run.length) * (movable_ends**2) + (open_ends**2)
            run_score = base_score * RUN_SCORE[run.length]
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
