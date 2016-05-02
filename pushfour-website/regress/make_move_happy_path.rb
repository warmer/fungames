#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/game.rb'

include Pushfour::Website

tcs = [
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, x: 0, y: 0},
      {player: 2, x: 0, y: 1},
      {player: 1, x: 0, y: 2},
      {player: 2, x: 0, y: 3},
    ],
    last_move: 0,
  },

  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, side: 'b', channel: 0},
      {player: 2, x: 0, y: 1},
      {player: 1, side: 'b', channel: 0},
      {player: 2, x: 1, y: 1},
      {player: 1, side: 'l', channel: 3},
      {player: 2, side: 'r', channel: 1},
      {player: 1, side: 't', channel: 1},
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

    create_result = Game.create_game(tc[:game])
    puts 'Result of game creation:'
    puts create_result.inspect
    game_id = create_result[:game]

    tc[:moves].each_with_index do |move, idx|
      puts "Move: #{move}"
      res = Game.make_move(move.merge(game_id: game_id))
      puts "ERROR: #{res[:errors].join(',')}" unless res[:errors].empty?
      puts
    end

    puts
  end
end
