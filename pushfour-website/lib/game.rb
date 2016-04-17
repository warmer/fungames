require 'securerandom'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative 'common.rb'
require_relative 'board.rb'
require_relative '../../pushfour-ai/common.rb'


module Pushfour
  module Website
    class Game
      include Common
      extend Common

      attr_reader :id, :board, :creator, :opponent, :first_move, :moves, :turn
      attr_reader :status, :game_detail, :board_string, :game_string
      attr_reader :player1, :player2
      attr_reader :anonymous, :p1_token, :p2_token, :p1_active, :p2_active, :game_token

      # uncomment to enable caching
#      def self.new(params)
#        @@cache ||= LruRedux::ThreadSafeCache.new(512)
#        found = false
#
#        if params[:id]
#          obj = @@cache[params[:id]]
#          found = true if obj
#        end
#        obj ||= super(params)
#
#        @@cache[obj.id] = obj if obj.id and not found
#
#        obj
#      end

      def initialize(params)
        @id = val_if_int(params.delete(:id))
        @p1_active = @p2_active = nil
        @p1_token = @p2_token = @game_token = nil

        # if we have an ID, it's the only parameter we need
        if @id
          raise ArgumentError, "Too many params for game: #{params.keys.sort}" if params.size > 0

          load_game
          @board = Board.new(id: @board_id)
        else
          @anonymous = nil
          # optional params
          @creator = val_if_int(params.delete(:creator))
          @opponent = val_if_int(params.delete(:opponent))
          @first_move = val_if_int(params.delete(:first_move))
          # TODO: how does this differ from creator?
          @user = val_if_int(params.delete(:user_id))

          @board_id = val_if_int(params.delete(:board_id))

          if @board_id
            raise ArgumentError, "Too many params for game: #{params.keys.sort}" if params.size > 0

            # load the given board ID
            @board = Board.new(id: @board_id)
          else
            # create a new board
            @board = Board.new(params)
          end

          create
        end
      end

      def make_move(params)
        player_info = nil

        return 'Game not active' unless @status == 0

        player_id = val_if_int(params.delete(:player))
        return 'Invalid player id' unless player_id and player_id > 0

        # load details about the current player
        player_info = Players.info_for(player_id)
        return 'Player not found' unless player_info

        players = [@player1, @player2]
        player_turn = players[@turn]
        return 'Out of turn move' unless player_turn == player_id

        x = val_if_int(params.delete(:x))
        y = val_if_int(params.delete(:y))
        side_raw = params.delete(:side)
        channel = val_if_int(params.delete(:channel))

        if side_raw or channel
          return '[x, y] and [side, channel] are mutually exclusive' if x or y
          return 'channel not specified with side' unless channel
          return 'side not specified with channel' unless side_raw
          side = side_raw.to_s[0] || ''
          return 'side not given a value' if side.empty?
          return 'invalid value for side' unless side == side_raw
          return 'invalid value for side' unless ['l', 'r', 't', 'b'].include? side

          depth = nil
          case side
            when 'l'
              y = channel
              x = @game_detail[:move_depth][:left][y]
            when 'r'
              y = channel
              x = @game_detail[:move_depth][:right][y]
            when 't'
              x = channel
              y = @game_detail[:move_depth][:top][x]
            when 'b'
              x = channel
              y = @game_detail[:move_depth][:bottom][x]
          end
        end

        return 'Invalid x' unless x
        return 'Invalid y' unless y
        return 'x out of range' unless x >= 0 and x < @board.width
        return 'y out of range' unless y >= 0 and y < @board.height

        mb = @game_detail[:movable_blocks]
        return "Cannot move to #{x}, #{y}" unless mb.include? [x, y]

        columns = %w(game movenumber player xlocation ylocation)
        values = [@id, move_number + 1, @turn, x, y]
        move_id = Database.insert(
          Database::MOVE_TABLE,
          columns,
          values
        )
        return 'Problem making move' unless move_id

        # make the move and update the status from the AI library
        offset = y * @board.width + x
        @board_string[offset] = @turn.to_s
        b = Pushfour::AI.make_board(@board_string, @board.width, @board.height, '+', '01')
        state = :in_progress
        state = :stalemate if b.movable_blocks.length == 0
        state = :ended if b.game_over and b.game_over > 0
        @turn = (@turn + 1) & 1 if state == :in_progress
        @status = status_id_for(state)

        result = Database.update(
          Database::GAME_TABLE,
          %w(turn status),
          [@turn, @status],
          @id
        )

        nil
      end

      # TODO: convert to class method of Game
      def self.list(params)
        errors = []
        games = []
        players = {}

        start = val_if_int(params.delete(:start))
        start = 0 unless start and start > 0

        res = Database.execute_query <<-HERE
          SELECT id,player1,player2,turn,status,board
          FROM #{Database::GAME_TABLE}
          ORDER BY id ASC
          LIMIT 50
          OFFSET #{start}
        HERE
        if res.size > 0
          res.each do |p|
            player1 = players[p[1]]
            player2 = players[p[2]]

            player1 ||= Players.info_for(p[1])
            player2 ||= Players.info_for(p[2])

            players[p[1]] = player1
            players[p[2]] = player2

            turn = player1 if p[3] == 0
            turn = player2 if p[3] == 1
            turn ||= {id: 0, name: "Player #{p[3] + 1}"}

            status = status_for(p[4])

            games << {id: p[0], player1: player1, player2: player2,
              turn: turn, status: status, board: p[5]
            }
          end
        else
          errors << 'No games found'
        end

        {games: games, errors: errors}
      end

      private

      def move_number
        move = 0

        res = Database.execute_query <<-HERE
          SELECT max(movenumber)
          FROM #{Database::MOVE_TABLE}
          WHERE game = #{@id}
          GROUP BY game;
        HERE

        move = res[0][0] if res and res[0]
        move
      end

      def create
        p1 = p2 = 0

        # "creator" will be set if this is NOT an anonymous game
        if @creator
          @player1 = [@creator, @opponent][@first_move]
          @player2 = [@opponent, @creator][@first_move]
        else
          @anonymous = 1
          @p1_token = SecureRandom.base64
          @p2_token = SecureRandom.base64
          @game_token = SecureRandom.base64(3)
        end

        persist
      end

      def persist
        @id = Database.insert(
          Database::GAME_TABLE,
          [:player1, :player2, :anonymous, :turn, :status, :board],
          [@player1, @player2, @anonymous, 0, status_id_for(:in_progress), @board.id]
        )
        raise 'Could not create game' unless @id and @id > 0
      end

      def process_xy(xy)
        xy.each_with_index do |row, y|
          row.each_with_index do |val, x|
            xy[y][x] = val & 0x0f
          end
        end
      end

      def load_moves(params)
        game_id = nil
        errors = []
        moves = []

        game_id = val_if_int(params.delete(:game_id))
        errors << 'Invalid game ID' unless game_id and game_id > 0

        if errors.size == 0
          res = Database.execute_query <<-HERE
            SELECT id,movenumber,player,xlocation,ylocation,movedate
            FROM #{Database::MOVE_TABLE}
            WHERE game = #{game_id}
            ORDER BY movenumber ASC;
          HERE
          res.each do |m|
            moves << {
              id: m[0], movenumber: m[1], player: m[2],
              xlocation: m[3], ylocation: m[4]
            }
          end
        end

        {game_id: game_id, moves: moves, errors: errors}
      end

      def populate_board_string(board_string, moves, width)
        moves.each do |move|
          offset = move[:ylocation] * width + move[:xlocation]
          board_string[offset] = ['0', '1'][move[:player]]
        end
        board_string
      end

      def make_game_string(board_string, height, width, turn)
        "+,#{board_string},#{height},#{width},2,01,#{turn}"
      end

      def load_game
        res = Database.execute_query <<-HERE
          SELECT player1,player2,turn,status,board
          FROM #{Database::GAME_TABLE}
          WHERE id = #{@id};
        HERE

        raise ArgumentError, 'Game status not found' unless res.size > 0
        res = res[0]
        @moves = load_moves(game_id: @id)[:moves]
        @player1 = res[0].to_i
        @player2 = res[1].to_i
        @turn = res[2].to_i
        @status = res[3].to_i
        @board_id = res[4].to_i

        @board = Board.new(id: @board_id)

        move_result = load_moves(game_id: @id)
        raise move_result[:errors] if move_result[:errors].size > 0

        @moves = move_result[:moves]
        @turn ||= moves.length & 1
        @board_string = populate_board_string(board.board_string, @moves, board.width)
        @game_string = make_game_string(@board_string, board.height, board.width, @turn)
        detail = Pushfour::AI.parse_game_string(@game_string)
        xy = process_xy(detail.board.xy)
        @game_detail = {
          xy: xy, move_depth: detail.board.move_depth, game_over: detail.board.game_over,
          movable_blocks: detail.board.movable_blocks
        }
      end
    end
  end
end