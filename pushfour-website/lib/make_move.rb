require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative 'game.rb'
require_relative 'create_game.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  module Website
    extend Common

    # TODO: move to Game object
    def self.make_move(params)
      errors = []
      game_info = player_info = nil
      game = nil

      game_id = val_if_int(params.delete(:game_id))
      return {errors: ['Invalid game id']} unless game_id and game_id > 0

      begin
        game = Game.new(id: game_id)
        error = game.make_move(params)
        errors << error if error
      rescue => e
        $stderr.puts e.message
        $stderr.puts e.backtrace.join("\n")
        errors << e.message
      end

      {errors: errors}
    end

    def self.load_game(params)
      game = game_info = board_info = game_id = nil
      errors = []

      game_id = val_if_int(params.delete(:game_id))
      errors << 'Invalid game ID' unless game_id and game_id > 0

      if errors.empty?
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
