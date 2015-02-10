require 'net/http'

def get(url)
  tries ||= 5
  uri = URI(url)
  res = Net::HTTP.get(uri)
rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  unless (tries -= 1).zero?
    sleep 5 * (5 - tries)
    retry
  end
else
  res
end

module Pushfour
  SERVER_URL = 'http://pushfour.net'

  PLAYER_0 = (1 << 0)
  PLAYER_1 = (1 << 1)
  PLAYER_MASK = (PLAYER_0 | PLAYER_1)
  UNMOVABLE_BLOCK = (1 << 2)
  PIECE_MASK = 0x0f

  MOVABLE_FROM_LEFT = (1 << 4)
  MOVABLE_FROM_LEFT_CLEAR = 0xffffffff ^ (1 << 4)
  MOVABLE_FROM_TOP = (1 << 5)
  MOVABLE_FROM_TOP_CLEAR = 0xffffffff ^ (1 << 5)
  MOVABLE_FROM_RIGHT = (1 << 6)
  MOVABLE_FROM_RIGHT_CLEAR = 0xffffffff ^ (1 << 6)
  MOVABLE_FROM_BOTTOM = (1 << 7)
  MOVABLE_FROM_BOTTOM_CLEAR = 0xffffffff ^ (1 << 7)
  MOVABLE_MASK = (MOVABLE_FROM_LEFT | MOVABLE_FROM_TOP | MOVABLE_FROM_RIGHT | MOVABLE_FROM_BOTTOM)

  OPEN_TO_LEFT = (1 << 8)
  OPEN_TO_TOP = (1 << 9)
  OPEN_TO_RIGHT = (1 << 10)
  OPEN_TO_BOTTOM = (1 << 11)
  OPEN_MASK = (OPEN_TO_LEFT | OPEN_TO_TOP | OPEN_TO_RIGHT | OPEN_TO_BOTTOM)

  RUN_HORIZ = (1 << 12)
  RUN_HORIZ_MASK = (0xf << 12)
  RUN_VERT = (1 << 16)
  RUN_VERT_MASK = (0xf << 16)
  RUN_FS = (1 << 20)
  RUN_FS_MASK = (0xf << 20)
  RUN_BS = (1 << 24)
  RUN_BS_MASK = (0xf << 24)
  RUN_MASK = (RUN_HORIZ | RUN_VERT | RUN_FS | RUN_BS)
  GAME_OVER_MASK = (RUN_HORIZ * 4 | RUN_VERT * 4 | RUN_FS * 4 | RUN_BS * 4)

  class Board
    attr_accessor :x, :y, :xy, :movable_blocks, :move_depth, :players, :game_over

    def initialize(opts = {})
      @game_over = false
      @movable_blocks = opts[:movable_blocks]
      @x = opts[:x]
      @y = opts[:y]
      @xy = opts[:xy]
      @players = opts[:players]
      @game_over = opts[:game_over]
      board_string = opts[:board_string]
      player_chars = opts[:player_chars]
      open_char = opts[:open_char]

      # Track depth of movability from left, top, right, bottom.
      # Default to movable all the way down to the bottom of the board.
      # As we traverse the board, change movability accordingly.
      @move_depth = {
        left: [x - 1] * y,
        right: [0] * y,
        top: [y - 1] * x,
        bottom: [0] * x,
      }

      @players = player_chars.map {|p| player_chars.index(p) + 1 } if player_chars

      # start building the board as arrays of ints, rather than a string
      if board_string
        # add pieces, blocks and run lengths for each player piece
        build_xy_from_string(board_string, @x, @y, open_char, player_chars)
        @movable_blocks = []
        @x.times do |xpos|
          @y.times do |ypos|
            case @xy[ypos][xpos] & PIECE_MASK
              when @players[0]
                block_depth(move_depth, xpos, ypos)
              when @players[1]
                block_depth(move_depth, xpos, ypos)
              when UNMOVABLE_BLOCK
                block_depth(move_depth, xpos, ypos)
            end
          end
        end

        # find open moves and set openness, movability bits
        x.times do |i|
          y.times do |j|
            # from which sides could the next move land?
            xy[j][i] |= MOVABLE_FROM_LEFT if move_depth[:left][j] == i
            xy[j][i] |= MOVABLE_FROM_RIGHT if move_depth[:right][j] == i
            xy[j][i] |= MOVABLE_FROM_TOP if move_depth[:top][i] == j
            xy[j][i] |= MOVABLE_FROM_BOTTOM if move_depth[:bottom][i] == j
            movable_blocks << [i, j] if (xy[j][i] & MOVABLE_MASK) > 0

            # which side are not yet blocked by another piece or obstacle?
            xy[j][i] |= OPEN_TO_LEFT if move_depth[:left][j] >= i
            xy[j][i] |= OPEN_TO_RIGHT if move_depth[:right][j] <= i
            xy[j][i] |= OPEN_TO_TOP if move_depth[:top][i] >= j
            xy[j][i] |= OPEN_TO_BOTTOM if move_depth[:bottom][i] <= j
            #open_blocks << [i, j] if (xy[j][i] & OPEN_MASK) > 0
          end
        end
      end
      raise 'No board string or board given - cannot create a new board' unless xy
    end

    def build_xy_from_string(board_string, x, y, open_char, player_chars)
      runs = Hash.new {|hash, key| hash[key] = {RUN_HORIZ => [], RUN_VERT => [], RUN_FS => [], RUN_BS => [] } }
      @xy = Array.new(y) {|idx| [0] * x}
      board_string.chars.each_with_index do |char, idx|
        xpos = idx % x
        ypos = idx / x

        case char
          when open_char
          when player_chars[0]
            @xy[ypos][xpos] = PLAYER_0
            block_depth(move_depth, xpos, ypos)
          when player_chars[1]
            @xy[ypos][xpos] = PLAYER_1
            block_depth(move_depth, xpos, ypos)
          else
            @xy[ypos][xpos] = UNMOVABLE_BLOCK
            block_depth(move_depth, xpos, ypos)
        end

        p = @xy[ypos][xpos] & PLAYER_MASK
        if p > 0
          # horizontal
          run = runs[p][RUN_HORIZ].delete([xpos-1, ypos]) || PieceRun.new(xpos, ypos, RUN_HORIZ)
          run.add(xpos, ypos)
          runs[p][RUN_HORIZ] << run

          # vertical
          run = runs[p][RUN_VERT].delete([xpos, ypos-1]) || PieceRun.new(xpos, ypos, RUN_VERT)
          run.add(xpos, ypos)
          runs[p][RUN_VERT] << run

          # backslash diag
          run = runs[p][RUN_BS].delete([xpos-1, ypos-1]) || PieceRun.new(xpos, ypos, RUN_BS)
          run.add(xpos, ypos)
          runs[p][RUN_BS] << run

          # forwardslash diag
          run = runs[p][RUN_FS].delete([xpos+1, ypos-1]) || PieceRun.new(xpos, ypos, RUN_FS)
          run.add(xpos, ypos)
          runs[p][RUN_FS] << run
        end
      end

      @game_over = 0
      runs.each do |player, dir_runs|
        dir_runs.each do |dir, run_list|
          run_list.each do |run|
            run.pieces.each do |pt|
              @xy[pt[1]][pt[0]] |= (run.pieces.size * dir)
              @game_over = player if run.pieces.size >= 4
            end
          end
        end
      end
    end

    # return a new board that reflects the move
    def move(x, y, player)
      raise "[#{x},#{y}] is not a valid move" unless movable_blocks.include?([x, y])

      game_over = @game_over
      prev_piece = @xy[y][x]
      # TODO: make movable_blocks a bit mask (using y integers)
      # then bits could be bit and set quite easily
      mb = []
      @movable_blocks.each do |block|
        mb << block.dup unless block == [x, y]
      end

      new_xy = []
      @xy.each_with_index do |row, idx|
        new_xy[idx] = row.dup
      end
      new_xy[y][x] = player | RUN_MASK

      # TODO: find game over condition

      # add to runs
      one_up = (y > 0 ? y - 1 : nil)
      one_down = (y < @y - 1 ? y + 1 : nil)
      one_left = (x > 0 ? x - 1 : nil)
      one_right = (x < @x - 1 ? x + 1 : nil)

      # horiz
      if one_left and new_xy[y][one_left] & PLAYER_MASK == player
        if one_right and new_xy[y][one_right] & PLAYER_MASK == player
          prev_depth = ((new_xy[y][one_left] & RUN_HORIZ_MASK) / RUN_HORIZ)
          aft_depth = ((new_xy[y][one_right] & RUN_HORIZ_MASK) / RUN_HORIZ)

          prev_depth.times do |depth|
            new_xy[y][one_left - depth] += RUN_HORIZ * (aft_depth + 1)
          end

          aft_depth.times do |depth|
            new_xy[y][one_right + depth] += RUN_HORIZ * (prev_depth + 1)
          end
          new_xy[y][x] += RUN_HORIZ * (prev_depth + aft_depth)
        else
          prev_depth = ((new_xy[y][one_left] & RUN_HORIZ_MASK) / RUN_HORIZ)
          prev_depth.times do |depth|
            new_xy[y][one_left - depth] += RUN_HORIZ
          end
          new_xy[y][x] += RUN_HORIZ * prev_depth
        end
      elsif one_right and new_xy[y][one_right] & PLAYER_MASK == player
        aft_depth = ((new_xy[y][one_right] & RUN_HORIZ_MASK) / RUN_HORIZ)
        aft_depth.times do |depth|
          new_xy[y][one_right + depth] += RUN_HORIZ
        end
        new_xy[y][x] += RUN_HORIZ * aft_depth
      end

      # vert
      if one_up and new_xy[one_up][x] & PLAYER_MASK == player
        if one_down and new_xy[one_down][x] & PLAYER_MASK == player
          prev_depth = ((new_xy[one_up][x] & RUN_VERT_MASK) / RUN_VERT)
          aft_depth = ((new_xy[one_down][x] & RUN_VERT_MASK) / RUN_VERT)

          prev_depth.times do |depth|
            new_xy[one_up - depth][x] += RUN_VERT * (aft_depth + 1)
          end

          aft_depth.times do |depth|
            new_xy[one_down + depth][x] += RUN_VERT * (prev_depth + 1)
          end
          new_xy[y][x] += RUN_VERT * (prev_depth + aft_depth)
        else
          prev_depth = ((new_xy[one_up][x] & RUN_VERT_MASK) / RUN_VERT)
          prev_depth.times do |depth|
            new_xy[one_up - depth][x] += RUN_VERT
          end
          new_xy[y][x] += RUN_VERT * prev_depth
        end
      elsif one_down and new_xy[one_down][x] & PLAYER_MASK == player
        aft_depth = ((new_xy[one_down][x] & RUN_VERT_MASK) / RUN_VERT)
        aft_depth.times do |depth|
          new_xy[one_down + depth][x] += RUN_VERT
        end
        new_xy[y][x] += RUN_VERT * aft_depth
      end

      # back diag
      if one_up and one_left and new_xy[one_up][one_left] & PLAYER_MASK == player
        if one_down and one_right and new_xy[one_down][one_right] & PLAYER_MASK == player
          prev_depth = ((new_xy[one_up][one_left] & RUN_BS_MASK) / RUN_BS)
          aft_depth = ((new_xy[one_down][one_right] & RUN_BS_MASK) / RUN_BS)

          prev_depth.times do |depth|
            new_xy[one_up - depth][one_left - depth] += RUN_BS * (aft_depth + 1)
          end

          aft_depth.times do |depth|
            new_xy[one_down + depth][one_right + depth] += RUN_BS * (prev_depth + 1)
          end
          new_xy[y][x] += RUN_BS * (prev_depth + aft_depth)
        else
          prev_depth = ((new_xy[one_up][one_left] & RUN_BS_MASK) / RUN_BS)
          prev_depth.times do |depth|
            new_xy[one_up - depth][one_left - depth] += RUN_BS
          end
          new_xy[y][x] += RUN_BS * prev_depth
        end
      elsif one_down and one_right and new_xy[one_down][one_right] & PLAYER_MASK == player
        aft_depth = ((new_xy[one_down][one_right] & RUN_BS_MASK) / RUN_BS)
        aft_depth.times do |depth|
          new_xy[one_down + depth][one_right + depth] += RUN_BS
        end
          new_xy[y][x] += RUN_BS * aft_depth
      end

      # fwd diag
      if one_up and one_right and new_xy[one_up][one_right] & PLAYER_MASK == player
        if one_down and one_left and new_xy[one_down][one_left] & PLAYER_MASK == player
          prev_depth = ((new_xy[one_up][one_right] & RUN_FS_MASK) / RUN_FS)
          aft_depth = ((new_xy[one_down][one_left] & RUN_FS_MASK) / RUN_FS)

          prev_depth.times do |depth|
            new_xy[one_up - depth][one_right + depth] += RUN_FS * (aft_depth + 1)
          end

          aft_depth.times do |depth|
            new_xy[one_down + depth][one_left - depth] += RUN_FS * (prev_depth + 1)
          end
          new_xy[y][x] += RUN_FS * (prev_depth + aft_depth)
        else
          prev_depth = ((new_xy[one_up][one_right] & RUN_FS_MASK) / RUN_FS)
          prev_depth.times do |depth|
            new_xy[one_up - depth][one_right + depth] += RUN_FS
          end
          new_xy[y][x] += RUN_FS * prev_depth
        end
      elsif one_down and one_left and new_xy[one_down][one_left] & PLAYER_MASK == player
        aft_depth = ((new_xy[one_down][one_left] & RUN_FS_MASK) / RUN_FS)
        aft_depth.times do |depth|
          new_xy[one_down + depth][one_left - depth] += RUN_FS
        end
        new_xy[y][x] += RUN_FS * aft_depth
      end

      game_over = new_xy[y][x] & GAME_OVER_MASK
      game_over = new_xy[y][x] & PLAYER_MASK if game_over > 0

      # pieces to the left - no longer movable from the right
      if prev_piece & OPEN_TO_RIGHT > 0
        (x).times do |offset|
          # stop when we encounter another obstacle
          break if new_xy[y][x - offset - 1] & PIECE_MASK > 0
          # pieces to the left of the new piece are no longer open to the right
          new_xy[y][x - offset - 1] ^= OPEN_TO_RIGHT
          new_xy[y][x - offset - 1] &= MOVABLE_FROM_RIGHT_CLEAR
          mb.delete([x - offset - 1, y]) if new_xy[y][x - offset - 1] & MOVABLE_MASK == 0
        end
        if x + 1 < @x
          # this will always be movable if it was previously open from this direction
          new_xy[y][x + 1] |= MOVABLE_FROM_RIGHT
          mb << [x + 1, y] unless mb.include?([x + 1, y])
        end
      end

      # pieces to the right - no longer movable from the left
      if prev_piece & OPEN_TO_LEFT > 0
        (@x - x - 1).times do |offset|
          # stop when we encounter another obstacle
          break if new_xy[y][x + offset + 1] & PIECE_MASK > 0
          # pieces to the right of the new piece are no longer open to the left
          new_xy[y][x + offset + 1] ^= OPEN_TO_LEFT
          new_xy[y][x + offset + 1] &= MOVABLE_FROM_LEFT_CLEAR
          mb.delete([x + offset + 1, y]) if new_xy[y][x + offset + 1] & MOVABLE_MASK == 0
        end
        if x > 0
          # this will always be movable if it was previously open from this direction
          new_xy[y][x - 1] |= MOVABLE_FROM_LEFT
          mb << [x - 1, y] unless mb.include?([x - 1, y])
        end
      end

      # pieces to the top - no longer movable from the bottom
      if prev_piece & OPEN_TO_BOTTOM > 0
        (y).times do |offset|
          # stop when we encounter another obstacle
          break if new_xy[y - offset - 1][x] & PIECE_MASK > 0
          new_xy[y - offset - 1][x] ^= OPEN_TO_BOTTOM
          new_xy[y - offset - 1][x] &= MOVABLE_FROM_BOTTOM_CLEAR
          mb.delete([x, y - offset - 1]) if new_xy[y - offset - 1][x] & MOVABLE_MASK == 0
        end
        if y + 1 < @y
          new_xy[y + 1][x] |= MOVABLE_FROM_BOTTOM
          mb << [x, y + 1] unless mb.include?([x, y + 1])
        end
      end

      # pieces to the bottom - no longer movable from the top
      if prev_piece & OPEN_TO_TOP > 0
        (@y - y - 1).times do |offset|
          # stop when we encounter another obstacle
          break if new_xy[y + offset + 1][x] & PIECE_MASK > 0
          new_xy[y + offset + 1][x] ^= OPEN_TO_TOP
          new_xy[y + offset + 1][x] &= MOVABLE_FROM_TOP_CLEAR
          mb.delete([x, y + offset + 1]) if new_xy[y + offset + 1][x] & MOVABLE_MASK == 0
        end
        if y > 0
          new_xy[y - 1][x] |= MOVABLE_FROM_TOP
          mb << [x, y - 1] unless mb.include?([x, y - 1])
        end
      end

      Board.new(xy: new_xy, x: @x, y: @y, players: @players, movable_blocks: mb, game_over: game_over)
    end

    def block_depth(move_depth, x, y)
      move_depth[:left][y] = x - 1 if x <= move_depth[:left][y]
      move_depth[:right][y] = x + 1 if x >= move_depth[:right][y]
      move_depth[:top][x] = y - 1 if y <= move_depth[:top][x]
      move_depth[:bottom][x] = y + 1 if y >= move_depth[:bottom][x]
    end
  end

  class PieceRun
    attr_reader :dir, :pieces

    def initialize(x, y, dir)
      @dir = dir
      @pieces = [[x, y]]
    end

    def add(x, y)
      return if [x, y] == @pieces[-1]
      @pieces << [x, y]
    end

    def length
      @pieces.size
    end

    def ==(other)
      return false unless other
      if other.is_a?(Array)
        return @pieces[-1] == other
      end
      return false if dir != other.dir
      return @pieces[-1] == other.pieces[-1]
    end
  end

  class Game
    attr_accessor :board, :turn, :id

    def initialize(opts = {})
      @board = opts[:board]
      @turn = opts[:turn]
      @id = opts[:id]
    end

    # this returns a new board with the move that was made
    def make_move(x, y, advance_turn = true)
      @board = @board.move(x, y, @turn)
      @turn = @board.players[@turn] || @board.players[0] if advance_turn
    end
  end

  def self.print_board(obj)
    xy = nil
    if obj.is_a?(Game)
      xy = obj.board.xy
    elsif obj.is_a?(Board)
      xy = obj.xy
    elsif obj.is_a?(Array)
      xy = obj
    else
      abort "Cannot print board for #{obj.class}"
    end

    xy.each do |row|
      vals = row.map {|b| sprintf('% 8x', b) }
      vals.each {|v| print "#{v} "}
      puts
    end
  end

  def self.block_depth(move_depth, x, y)
    move_depth[:left][y] = x - 1 if x <= move_depth[:left][y]
    move_depth[:right][y] = x + 1 if x >= move_depth[:right][y]
    move_depth[:top][x] = y - 1 if y <= move_depth[:top][x]
    move_depth[:bottom][x] = y + 1 if y >= move_depth[:bottom][x]
  end

  def self.make_board(string, x, y, open_char, players)
    Board.new(x: x, y: y, board_string: string, open_char: open_char, player_chars: players)
  end

  def self.game_list(player)
    res = get "#{SERVER_URL}/getgames.php?playerid=#{player.to_i}"
    res.split(',').map {|id| id.to_i}
  end

  def self.game_info(game_id, player)
    res = get "#{SERVER_URL}/gameinfo.php?gameid=#{game_id.to_i}&playerid=#{player.to_i}"
    parse_game_string(res, game_id)
  end

  def self.parse_game_string(str, id = nil)
    info = str.split(',')
    open_char = info[0]
    board = info[1]
    y = info[2].to_i
    x = info[3].to_i
    player_count = info[4].to_i
    chars = info[5].chars.map {|c| c}
    player_color = info[6]
    player_num = chars.index(player_color) + 1

    board = Board.new(x: x, y: y, board_string: board, open_char: open_char, player_chars: chars)
    Game.new(board: board, turn: player_num, id: id)
  end

  def self.send_website_move(game, move, opts = {})
    player_id = opts[:player_id]
    block = game.board.xy[move[1]][move[0]]

    side = nil
    channel = nil
    if block & MOVABLE_FROM_LEFT > 0
      side = :left
      # TODO: website doesn't start at 0; change the website
      channel = move[1]

    elsif block & MOVABLE_FROM_RIGHT > 0
      side = :right
      # TODO: website doesn't start at 0; change the website
      channel = move[1]

    elsif block & MOVABLE_FROM_TOP > 0
      side = :top
      # TODO: website doesn't start at 0; change the website
      channel = move[0]

    elsif block & MOVABLE_FROM_BOTTOM > 0
      side = :bottom
      # TODO: website doesn't start at 0; change the website
      channel = move[0]

    else
      raise 'Cannot find the channel for the given move'
    end

    send_move(game.id, player_id, side, channel, opts)
  end

  def self.send_move(game_id, player, side, channel, opts = {})
    side = {left: 'l', right: 'r', top: 't', bottom: 'b'}[side]
    params = {
      'game' => game_id,
      'player' => player,
      'side' => side,
      'channel' => channel
    }
    param_str = params.to_a.map {|kv| kv.join('=')}.join('&')

    if opts[:echo_params]
      puts param_str
    else
      res = get "#{SERVER_URL}/manager.php?#{param_str}"
    end
  end
end
