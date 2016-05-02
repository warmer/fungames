#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/create_game.rb'
require_relative '../lib/make_move.rb'

include Pushfour::Website

tcs = [
  { game: {height: 4, width: 5, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, x: 0, y: 0},
      # cannot move to occupied block
      {player: 2, x: 0, y: 0},

      # cannot move out of bounds
      {player: 2, x: -1, y: 0},
      {player: 2, x: 5, y: 0},
      {player: 2, x: 0, y: -1},
      {player: 2, x: 0, y: 4},

      # move out of turn
      {player: 1, x: 0, y: 1},
      # invalid player
      {player: 0, x: 1, y: 0},
      # player not found
      {player: 3, x: 1, y: 0},
      # conflicting parameters
      {player: 2, x: 1, y: 0, side: 'b'},
      # channel not specified
      {player: 2, side: 'b'},
      # channel not a number
      {player: 2, side: 'b', channel: 'one'},
      # channel too small
      {player: 2, side: 'b', channel: -1},
      # channel too big
      {player: 2, side: 'b', channel: 4},
      # side not specified
      {player: 2, channel: 1},
      # side too verbose
      {player: 2, side: 'bottom', channel: 1},
      # not a valid side
      {player: 2, side: 'f', channel: 1},

      # make some successful moves
      {player: 2, x: 4, y: 0}, # top right corner
      {player: 1, x: 0, y: 1},
      {player: 2, x: 4, y: 3}, # bottom right corner
      {player: 1, x: 0, y: 2},
      {player: 2, x: 0, y: 3}, # bottom left corner

      # check that no moves can be made from any corner
      {player: 1, side: 't', channel: 0},
      {player: 1, side: 't', channel: 4},
      {player: 1, side: 'b', channel: 0},
      {player: 1, side: 'b', channel: 4},
      {player: 1, side: 'l', channel: 0},
      {player: 1, side: 'l', channel: 3},
      {player: 1, side: 'r', channel: 0},
      {player: 1, side: 'r', channel: 3},

      # make more successful moves
      {player: 1, x: 1, y: 1},
      {player: 2, x: 1, y: 2},
      {player: 1, x: 2, y: 1},
      {player: 2, x: 2, y: 2},
      # this should be the winning move
      {player: 1, x: 3, y: 1},

      # neither player should be able to move
      {player: 2, x: 3, y: 2},
      {player: 1, x: 4, y: 1},
    ],
    last_move: 0,
  },
]
seed = 4

Harness.run_test(mock_db: true) do
  Registration.register(
    name: 'user1',
    password: 'test',
    password2: 'test')
  Registration.register(
    name: 'user2',
    password: 'test',
    password2: 'test')

  db_result = Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = CreateGame.create_game(tc[:game])
    puts 'Result of game creation:'
    puts create_result.inspect
    game_id = create_result[:game]

    tc[:moves].each_with_index do |move, idx|
      puts "Move : #{move}"
      res = MakeMove.make_move(move.merge(game_id: game_id))
      puts "ERROR: #{res[:errors].join(',')}" unless res[:errors].empty?
      puts
    end

    puts
  end
end
