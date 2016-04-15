require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative 'create_game.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  module Website
    extend Common

    def self.move_number(params)
      errors = []
      move = 0

      game_id = val_if_int(params.delete(:game_id))
      errors << 'Invalid game id' unless game_id and game_id > 0

      if errors.size == 0
        res = Database.execute_query <<-HERE
          SELECT max(movenumber)
          FROM #{Database::MOVE_TABLE}
          WHERE game = #{game_id}
          GROUP BY game;
        HERE
        move = res[0][0] if res and res[0]
      end

      {errors: errors, move_number: move}
    end

    # TODO: move to Game object
    def self.make_move(params)
      errors = []
      game_info = player_info = nil

      game_id = val_if_int(params.delete(:game_id))
      errors << 'Invalid game id' unless game_id and game_id > 0
      player_id = val_if_int(params.delete(:player))
      errors << 'Invalid player id' unless player_id and player_id > 0

      # load details about the current player
      if errors.size == 0
        player_info = Players.info_for(player_id)
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
        x = val_if_int(params.delete(:x))
        y = val_if_int(params.delete(:y))
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
        move_id = Database.insert(
          Database::MOVE_TABLE,
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
        b = Pushfour::AI.make_board(board_string, board[:width], board[:height], '+', '01')
        status = :in_progress
        status = :stalemate if b.movable_blocks.length == 0
        status = :ended if b.game_over and b.game_over > 0
        turn = (turn + 1) & 1 if status == :in_progress
        status_id = status_id_for(status)

        result = Database.update(
          Database::GAME_TABLE,
          %w(turn status),
          [turn, status_id],
          game_id
        )
      end

      {errors: errors}
    end

    def self.load_game(params)
      game = game_info = board_info = game_id = nil
      errors = []

      game_id = val_if_int(params.delete(:game_id))
      errors << 'Invalid game ID' unless game_id and game_id > 0

      if errors.size == 0
        begin
          game = Game.new(id: game_id)
        rescue => e
          errors << e.message
        else
          game_info = {id: game.id, player1: game.player1, player2: game.player2,
            players: [game.player1, game.player2], turn: game.turn, status: game.status,
            game_detail: game.game_detail, moves: game.moves
          }

          board = game.board
          board_info = {width: board.width, height: board.height, board_string: game.board_string}
        end
      end

      {
        errors: errors, game_id: game_id,
        board: board_info, game: game_info
      }
    end
  end
end
