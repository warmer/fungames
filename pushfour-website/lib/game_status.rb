require_relative 'common.rb'
require_relative 'game.rb'

module Pushfour
  module Website
    module GameStatus
      extend Common

      # TODO: convert to class method of Game
      def self.list(params)
        Game.list(params)
      end

      def self.game_string(params)
        Game.new(id: params.delete(:game_id)).game_string rescue nil
      end

      def self.get_status(params)
        result = {status: nil, moves: nil, current_turn: nil, errors: []}
        game_id = val_if_int(params.delete(:game_id))
        if game_id and game_id > 0
          begin
            game = Game.new(id: game_id)
            result[:status] = game.status
            result[:moves] = game.moves
            result[:current_turn] = game.turn
          rescue => e
            result[:errors] << e.message
          end
        else
          result[:errors] << 'Invalid game ID'
        end

        result
      end
    end
  end
end
