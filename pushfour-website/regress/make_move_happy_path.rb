#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/create_game.rb'
require_relative '../lib/game_status.rb'
require_relative '../lib/make_move.rb'

tcs = [
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, x: 0, y: 0},
      {player: 2, x: 0, y: 0},
      {player: 1, x: 0, y: 0},
      {player: 2, x: 0, y: 0},
    ],
    last_move: 0,
  },
]
seed = 4

Harness.run_test(mock_db: true) do
  Pushfour::Registration.register(
    name: 'user1',
    password: 'test',
    password2: 'test')
  Pushfour::Registration.register(
    name: 'user2',
    password: 'test',
    password2: 'test')

  db_result = Pushfour::Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = Pushfour::WebGame.create_game(tc[:game])
    puts 'Result of game creation:'
    puts create_result.inspect
    game_id = create_result[:game]

    tc[:moves].each_with_index do |move, idx|
      res = Pushfour::WebGame.make_move(
        game_id: game_id, player: move[:player], x: move[:x], y: move[:y]
      )
      puts 'Make move result:'
      puts res
      puts
    end

    status = Pushfour::WebGame.get_status(game_id: game_id, last_move: tc[:last_move])
    puts 'Get status result:'
    puts status.inspect

    puts
  end
end
