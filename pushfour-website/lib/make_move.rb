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
        move = res[0][0] if res and res[0]
      end

      {errors: errors, move_number: move}
    end

    def self.make_move(params)
      errors = []
      game_info = player_info = nil

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game id' unless game_id and game_id > 0
      player_id = val_if_int(params[:player])
      errors << 'Invalid player id' unless player_id and player_id > 0

      # load details about the current player
      if errors.size == 0
        player_info = Pushfour::Players.info_for(player_id)
        errors << 'Player not found' unless player_info
      end

      # load the game details
      if errors.size == 0
        game_info = load_game(game_id: game_id)
        errors.concat(game_info[:errors])
      end

      # validate some game state
      if errors.size == 0
        players = [game_info[:game][:player1], game_info[:game][:player2]]
        player_turn = players[game_info[:game][:turn]]
        errors << 'Out of turn move' unless player_turn == player_id
        errors << 'Game not active' unless game_info[:game][:status] == 0
      end

      # check that this is a legal move
      if errors.size == 0
        x = val_if_int(params[:x])
        y = val_if_int(params[:y])
        errors << 'Invalid x' unless x
        errors << 'Invalid y' unless y

        mb = game_info[:game][:game_detail][:movable_blocks]
        errors << "Cannot move to #{x}, #{y}" unless mb.include? [x, y]
      end

      if errors.size == 0
        # TODO: get the maximum move number
        move_num = move_number(game_id: game_id)[:move_number] + 1

        columns = %w(game movenumber player xlocation ylocation)
        values = [game_id, move_num, game_info[:game][:turn], x, y]
        move_id = Pushfour::Database.insert(
          Pushfour::Database::MOVE_TABLE,
          columns,
          values
        )
        errors << 'Problem making move' unless move_id
      end

      # update the game state
      if errors.size == 0
        board = game_info[:board]
        board_string = board[:board_string]
        game = game_info[:game]
        # make the move and update the status from the AI library
        offset = y * board[:width] + x
        turn = (player_id == game[:player1]) ? 0 : 1
        board_string[offset] = turn.to_s if player_id == game[:player1]
        board_string[offset] = turn.to_s if player_id == game[:player2]
        b = Pushfour.make_board(board_string, board[:width], board[:height], '+', '01')
        status = :in_progress
        status = :stalemate if b.movable_blocks.length == 0
        status = :ended if b.game_over and b.game_over > 0
        turn = (turn + 1) & 1 if status == :in_progress
        status_id = status_id_for(status)

        result = Pushfour::Database.update(
          Pushfour::Database::GAME_TABLE,
          %w(turn status),
          [turn, status_id],
          game_id
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

    def self.populate_board_string(board_string, moves, width)
      moves.each do |move|
        offset = move[:ylocation] * width + move[:xlocation]
        board_string[offset] = ['0', '1'][move[:player]]
      end
      board_string
    end

    def self.make_game_string(board_string, height, width, turn)
      "+,#{board_string},#{height},#{width},2,01,#{turn}"
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
            players: [g[0], g[1]],
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
              game[:turn] ||= moves.length & 1
              board_string = populate_board_string(board_string, moves, width)
              game_string = make_game_string(board_string, height, width, game[:turn])
              puts "Game string: #{game_string}"
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
