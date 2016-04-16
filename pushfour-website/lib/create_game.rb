require_relative 'common.rb'
require_relative 'players.rb'
require_relative 'board.rb'
require_relative 'game.rb'

module Pushfour
  module Website
    module CreateGame
      extend Common

      def self.create_game(params)
        board = game = board_id = game_id = nil

        height = val_if_int(params.delete(:height)) || 0
        width = val_if_int(params.delete(:width)) || 0
        obstacles = val_if_int(params.delete(:obstacles)) || 0
        # optional params
        creator = val_if_int(params.delete(:creator))
        opponent = val_if_int(params.delete(:opponent))
        first_move = val_if_int(params.delete(:first_move))
        user = params.delete(:user_id)
        # test hook for creating deterministic output
        rand_seed = val_if_int(params.delete(:rand_seed))

        errors = []

        errors << 'Board height must be between 4 and 15' unless height >= 4 and height <= 15
        errors << 'Board width must be between 4 and 15' unless width >= 4 and width <= 15
        errors << 'There must be a positive number of obstacles' unless obstacles >= 0

        if creator
          errors << 'Could not find creating user' unless Players.info_for(creator)
          errors << 'Opponent not specified' unless opponent
          errors << 'Could not find opponent' unless opponent and Players.info_for(opponent)
          errors << 'Must specify which opponent has the first move' unless first_move
          errors << 'First move out of bounds' unless first_move and [0, 1].include?(first_move)
          errors << 'Signed in user does not match creator' unless user == creator
          errors << 'Opponent cannot be self' if user == opponent
        #elsif first_move or opponent
        else
          errors << 'May not create games anonymously'
        end

        unless errors.size > 0
          begin
            board = Board.new(height: height, width: width, obstacles: obstacles,
              rand_seed: rand_seed)
            board_id = board.id
            game = Game.new(creator: creator, opponent: opponent,
              first_move: first_move, board_id: board_id)
            game_id = game.id
          rescue => e
            errors << e.message
            $stderr.puts e.backtrace.join("\n")
            errors << 'Could not create board or game'
            board_id = nil
            game_id = nil
          end
        end

        {errors: errors, board: board_id, game: game_id}
      end
    end
  end
end
