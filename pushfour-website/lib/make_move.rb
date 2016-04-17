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
    module MakeMove
      extend Common

      # TODO: move to Game object
      def self.make_move(params)
        game = nil

        game_id = val_if_int(params.delete(:game_id))
        return {errors: ['Invalid game id']} unless game_id and game_id > 0

        begin
          game = Game.new(id: game_id)
        rescue => e
          return {errors: [e.message]}
        end

        error = game.make_move(params)
        return {errors: [error]} if error

        {errors: []}
      end

      def self.load_game(params)
        game = nil

        game_id = val_if_int(params.delete(:game_id))
        return {errors: ['Invalid game'], game: nil} unless game_id and game_id > 0

        begin
          game = Game.new(id: game_id)
        rescue => e
          return {errors: [e.message], game: nil}
        end

        { errors: [],
          game: {
            id: game.id,
            players: [game.player1, game.player2],
            turn: game.turn,
            status: game.status,
            game_detail: game.game_detail,
            moves: game.moves,
          },
          board: {
            width: game.board.width,
            height: game.board.height,
            board_string: game.board_string,
          },
        }
      end
    end
  end
end
