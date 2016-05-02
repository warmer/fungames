#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/game.rb'

obs_max = (225 / 4) + 1
tcs = [
  {height: 7, width: 7, obstacles: 4, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 15, width: 15, obstacles: obs_max, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 4, width: 15, obstacles: 10, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 15, width: 4, obstacles: 10, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 4, width: 4, obstacles: 1, creator: 1, opponent: 2, first_move: 0, user_id: 1},
  {height: 4, width: 4, obstacles: 1, creator: 2, opponent: 1, first_move: 1, user_id: 2},
]
seed = 4

include Pushfour::Website

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

    create_result = Game.create_game(tc)
    puts 'Result of game creation:'
    puts create_result.inspect

    game_result = Database.execute_query <<-HERE
      SELECT id,player1,player2,status,turn,board FROM #{Database::GAME_TABLE}
    HERE
    board_result = Database.execute_query <<-HERE
      SELECT id,width,height,boardstring FROM #{Database::BOARD_TABLE}
    HERE

    puts 'Game table after running test case:'
    puts game_result.inspect
    puts 'Board table after running test case:'
    puts board_result.inspect

    puts
  end
end
