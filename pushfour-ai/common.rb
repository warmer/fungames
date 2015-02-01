require 'net/http'

def get(url)
  tries ||= 5
  uri = URI(url)
  res = Net::HTTP.get(uri)
rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
  unless (tries -= 1).zero?
    sleep 5 * (5 - retries)
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
  MOVABLE_FROM_TOP = (1 << 5)
  MOVABLE_FROM_RIGHT = (1 << 6)
  MOVABLE_FROM_BOTTOM = (1 << 7)
  MOVABLE_MASK = (MOVABLE_FROM_LEFT | MOVABLE_FROM_TOP | MOVABLE_FROM_RIGHT | MOVABLE_FROM_BOTTOM)

  OPEN_TO_LEFT = (1 << 8)
  OPEN_TO_TOP = (1 << 9)
  OPEN_TO_RIGHT = (1 << 10)
  OPEN_TO_BOTTOM = (1 << 11)
  OPEN_MASK = (OPEN_TO_LEFT | OPEN_TO_TOP | OPEN_TO_RIGHT | OPEN_TO_BOTTOM)

  class Board
    attr_accessor :x, :y, :xy, :open_blocks, :movable_blocks, :move_depth, :players

    def initialize(opts = {})
      @open_blocks = []
      @movable_blocks = []
      @x = opts[:x]
      @y = opts[:y]
      @xy = opts[:xy]
      @players = opts[:players]
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
        build_xy_from_string(board_string, x, y, open_char, player_chars)
      else
        x.times do |xpos|
          y.times do |ypos|
            case xy[ypos][xpos] & PIECE_MASK
              when @players[0]
                block_depth(move_depth, xpos, ypos)
              when @players[1]
                block_depth(move_depth, xpos, ypos)
              when UNMOVABLE_BLOCK
                block_depth(move_depth, xpos, ypos)
            end
          end
        end
      end
      raise 'No board string or board given - cannot create a new board' unless xy

      # find open moves
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
          open_blocks << [i, j] if (xy[j][i] & OPEN_MASK) > 0
        end
      end
    end

    def build_xy_from_string(board_string, x, y, open_char, player_chars)
      @xy = Array.new(y) {|idx| [0] * x}
      board_string.chars.each_with_index do |char, idx|
        xpos = idx % x
        ypos = idx / x

        case char
          when open_char
          when player_chars[0]
            xy[ypos][xpos] = PLAYER_0
            block_depth(move_depth, xpos, ypos)
          when player_chars[1]
            xy[ypos][xpos] = PLAYER_1
            block_depth(move_depth, xpos, ypos)
          else
            xy[ypos][xpos] = UNMOVABLE_BLOCK
            block_depth(move_depth, xpos, ypos)
        end
      end
    end

    # return a new board that reflects the move
    def move(x, y, player)
      raise "[#{x},#{y}] is not a valid move" unless movable_blocks.include?([x, y])

      new_xy = []
      @xy.each_with_index do |row, idx|
        new_xy[idx] = row.dup
      end
      new_xy[y][x] = player

      Board.new(xy: new_xy, x: @x, y: @y, players: @players)
    end

    def block_depth(move_depth, x, y)
      move_depth[:left][y] = x - 1 if x <= move_depth[:left][y]
      move_depth[:right][y] = x + 1 if x >= move_depth[:right][y]
      move_depth[:top][x] = y - 1 if y <= move_depth[:top][x]
      move_depth[:bottom][x] = y + 1 if y >= move_depth[:bottom][x]
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
