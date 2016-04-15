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

      attr_reader :id, :board, :creator, :opponent, :first_move, :moves, :turn
      attr_reader :status, :game_detail, :board_string, :game_string
      attr_reader :player1, :player2

      # TODO: implement caching on object level; override the 'new' class method

      def initialize(params)
        @id = val_if_int(params.delete(:id))

        # if we have an ID, it's the only parameter we need
        if @id
          if params.size > 0
            raise ArgumentError, "Given game ID, too many params: #{params.keys.sort}"
          end

          load_game
          @board = Board.new(id: @board_id)
        else
          # optional params
          @creator = val_if_int(params.delete(:creator))
          @opponent = val_if_int(params.delete(:opponent))
          @first_move = val_if_int(params.delete(:first_move))
          # TODO: how does this differ from creator?
          @user = val_if_int(params.delete(:user_id))

          @board_id = val_if_int(params.delete(:board_id))

          if @board_id
            if params.size > 0
              raise ArgumentError, "Too many parameters given: #{params.keys.sort}"
            end

            @board = Board.new(id: @board_id)
          else
            @board = Board.new(params)
          end

          create_game
        end

        @persisted = params.delete(:persisted)
        @persisted = false if @persisted.nil?

        load_game if @id
      end

      # returns true if this game is persisted to the datbase
      def persisted?
        return @persisted
      end

      # persists this game to database
      def persist!
        # TODO: persist the game to the database
        @persisted = true
      end

      private

      def create_game
        if creator
          p1 = [@creator, @opponent][@first_move]
          p2 = [@opponent, @creator][@first_move]
          @id = Database.insert(
            Database::GAME_TABLE,
            [:player1, :player2, :turn, :status, :board],
            [p1, p2, 0, status_id_for(:in_progress), @board.id]
          )
        else
          @id = Database.insert(
            Database::GAME_TABLE,
            [:player1, :player2, :turn, :status, :board],
            [0, 0, 0, status_id_for(:in_progress), @board.id]
          )
          raise 'Could not create game' unless @id and @id > 0
        end
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
        if res.size > 0
          res = res[0]
          @moves = load_moves(game_id: @id)[:moves]
          @player1 = res[0].to_i
          @player2 = res[1].to_i
          @turn = res[2].to_i
          @status = res[3].to_i
          @board_id = res[4].to_i
        else
          raise ArgumentError, 'Game status not found'
        end

        @board = Board.new(id: @board_id)

        move_result = load_moves(game_id: @id)

        if move_result[:errors].size == 0
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
        else
          errors << move_result[:errors]
          errors.flatten!
          raise errors
        end
      end
    end
  end
end
