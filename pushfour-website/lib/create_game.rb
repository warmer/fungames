require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  class CreateGame
    extend Pushfour::Common

    def self.create_game(params)
      board = game = board_string = nil

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
        blocks = (0...space_count).to_a.sample(obstacles, random: rand)
        board_string = '+' * space_count
        blocks.each do |idx|
          board_string[idx] = '#'
        end
      end

      {errors: errors, notes: notes, board_string: board_string}
    end

  end
end
