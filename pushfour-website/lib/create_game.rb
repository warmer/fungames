require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  class WebGame
    extend Pushfour::Common

    def self.create_game(params)
      board = game = board_id = game_id = nil

      height = val_if_int(params[:height]) || 0
      width = val_if_int(params[:width]) || 0
      obstacles = val_if_int(params[:obstacles]) || 0
      # optional params
      creator = val_if_int(params[:creator])
      opponent = val_if_int(params[:opponent])
      first_move = val_if_int(params[:first_move])
      user = params[:user_id]
      # test hook for creating deterministic output
      rand_seed = val_if_int(params[:rand_seed])
      rand = (rand_seed ? Random.new(rand_seed) : Random.new)

      errors = []
      notes = []

      errors << 'Board height must be between 4 and 15' unless height >= 4 and height <= 15
      errors << 'Board width must be between 4 and 15' unless width >= 4 and width <= 15
      errors << 'There must be a positive number of obstacles' unless obstacles >= 0

      if creator
        errors << 'Could not find creating user' unless Pushfour::Players.info_for(creator)
        errors << 'Opponent not specified' unless opponent
        errors << 'Could not find opponent' unless opponent and Pushfour::Players.info_for(opponent)
        errors << 'Must specify which opponent has the first move' unless first_move
        errors << 'First move out of bounds' unless first_move and [0, 1].include?(first_move)
        errors << 'Signed in user does not match creator' unless user == creator
        errors << 'Opponent cannot be self' if user == opponent
      elsif first_move or opponent
        errors << 'Unexpected game creation parameters provided'
      end

      unless errors.size > 0
        space_count = height * width
        ob_count = [space_count / 4, obstacles].min
        notes << "Obstacle count reduced to #{ob_count}" unless ob_count == obstacles
        blocks = (0...space_count).to_a.sample(ob_count, random: rand)
        board_string = '+' * space_count
        blocks.each do |idx|
          board_string[idx] = '#'
        end
        board_id = Pushfour::Database.insert(
          Pushfour::Database::BOARD_TABLE,
          [:width, :height, :boardstring],
          [width, height, board_string]
        )
        if board_id and board_id > 0
          if creator
            p1 = [creator, opponent][first_move]
            p2 = [opponent, creator][first_move]
            game_id = Pushfour::Database.insert(
              Pushfour::Database::GAME_TABLE,
              [:player1, :player2, :turn, :status, :board],
              [p1, p2, 0, status_id_for(:in_progress), board_id]
            )
          else
            game_id = Pushfour::Database.insert(
              Pushfour::Database::GAME_TABLE,
              [:player1, :player2, :turn, :status, :board],
              [0, 0, 0, status_id_for(:in_progress), board_id]
            )
            errors << 'Could not create game' unless game_id and game_id > 0
          end

        else
          errors << 'Could not insert board into database'
        end
      end

      {errors: errors, notes: notes, board: board_id, game: game_id}
    end
  end
end
