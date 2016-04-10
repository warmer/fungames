require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative 'create_game.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  class WebGame
    extend Pushfour::Common

    def self.move_number(params)
      errors = []
      move = 0

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game id' unless game_id and game_id > 0

      if errors.size == 0
        res = Pushfour::Database.execute_query <<-HERE
          SELECT max(movenumber)
          FROM #{Pushfour::Database::MOVE_TABLE}
          WHERE game = #{game_id}
          GROUP BY game;
        HERE
        if res and res[0]
          move = res[0][0]
        end
      end

      {errors: errors, move_number: move}
    end

    def self.make_move(params)
      errors = []

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game id' unless game_id and game_id > 0

      player = val_if_int(params[:player])
      # TODO: validate player
      x = params[:x]
      y = params[:y]
      # TODO: validate x, y

      if errors.size == 0
        # TODO: get the maximum move number
        move_num = move_number(game_id: game_id)[:move_number] + 1

        columns = %w(game movenumber player xlocation ylocation)
        values = [game_id, move_num, player, x, y]
        Pushfour::Database.insert(
          Pushfour::Database::MOVE_TABLE,
          columns,
          values
        )
      end

      {errors: errors}
    end

    def self.process_xy(xy)
      xy.each_with_index do |row, y|
        row.each_with_index do |val, x|
          xy[y][x] = val & 0x0f
        end
      end
    end

    def self.load_moves(params)
      game_id = nil
      errors = []
      moves = []

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game ID' unless game_id and game_id > 0

      if errors.size == 0
        res = Pushfour::Database.execute_query <<-HERE
          SELECT id,movenumber,player,xlocation,ylocation,movedate
          FROM #{Pushfour::Database::MOVE_TABLE}
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

    def self.load_game(params)
      board = game = board_id = game_id = moves = game_string = nil
      errors = []

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game ID' unless game_id and game_id > 0

      if errors.size == 0
        res = Pushfour::Database.execute_query <<-HERE
          SELECT player1,player2,turn,status,board
          FROM #{Pushfour::Database::GAME_TABLE}
          WHERE id = #{game_id};
        HERE
        if res.size > 0
          g = res[0]
          board_id = g[4]
          game = {
            id: game_id, player1: g[0], player2: g[1],
            turn: g[2], status: g[3], board_id: board_id
          }
          res = Pushfour::Database.execute_query <<-HERE
            SELECT width,height,boardstring
            FROM #{Pushfour::Database::BOARD_TABLE}
            WHERE id = #{board_id};
          HERE

          if res.size > 0
            b = res[0]
            width = b[0]
            height = b[1]
            board_string = b[2]
            move_result = load_moves(game_id: game_id)
            if move_result[:errors].size == 0
              moves = move_result[:moves]
              moves.each do |move|
                offset = move[:ylocation] * width + move[:xlocation]
                board_string[offset] = ['0', '1'][move[:player]]
              end
              game_string = "+,#{board_string},#{height},#{width},2,01,#{game[:turn].to_s}"
              detail = Pushfour.parse_game_string(game_string)
              xy = process_xy(detail.board.xy)
              game[:game_detail] = {
                xy: xy, move_depth: detail.board.move_depth, game_over: detail.board.game_over,
                movable_blocks: detail.board.movable_blocks
              }
            else
              errors << move_result[:errors]
              errors.flatten!
            end
            board = {id: board_id, width: width, height: height, board_string: board_string}
          else
            errors << 'Could not find the board for the game'
          end

        else
          errors << 'Game not found'
        end
      end

      {
        errors: errors, game_id: game_id, board_id: board_id,
        board: board, game: game, moves: moves
      }
    end

  end
end
