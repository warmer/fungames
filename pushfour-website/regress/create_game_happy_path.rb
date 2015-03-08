#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/create_game.rb'

tcs = [
  {height: 7, width: 7, obstacles: 4},
  {height: 4, width: 4, obstacles: 0},
  {height: 15, width: 15, obstacles: (225 / 4) + 1},
  {height: 4, width: 15, obstacles: 10},
  {height: 15, width: 4, obstacles: 10},
  {height: 4, width: 4, obstacles: 1, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 4, width: 4, obstacles: 1, creator: 2, opponent: 1, first_move: 1, user_id: 2},
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

    create_result = Pushfour::CreateGame.create_game(tc)
    puts 'Result of game creation:'
    puts create_result.inspect

    game_result = Pushfour::Database.execute_query <<-HERE
      SELECT * FROM #{Pushfour::Database::GAME_TABLE}
    HERE
    board_result = Pushfour::Database.execute_query <<-HERE
      SELECT * FROM #{Pushfour::Database::BOARD_TABLE}
    HERE

    puts 'Game table after running test case:'
    puts game_result.inspect
    puts 'Board table after running test case:'
    puts board_result.inspect

    puts
  end
end
