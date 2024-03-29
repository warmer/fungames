#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/player.rb'
require_relative '../lib/game.rb'

include Pushfour::Website

games = [
  {height: 4, width: 7, obstacles: 4},
  {height: 7, width: 4, obstacles: 1, creator: 1, opponent: 2, first_move: 0, user_id: 1},
]
moves = [
  {game: 1, movenumber: 1, player: 0, xlocation: 0, ylocation: 0},
  {game: 1, movenumber: 2, player: 1, xlocation: 0, ylocation: 1},
  {game: 1, movenumber: 3, player: 0, xlocation: 1, ylocation: 1},
]
tcs = [
  {user_id: 1, game_id: 1},
  {user_id: 2, game_id: 1},
  {game_id: 1},
]
seed = 4

Harness.run_test(mock_db: true) do
  Player.register(
    name: 'user1',
    password: 'test',
    password2: 'test')
  Player.register(
    name: 'user2',
    password: 'test',
    password2: 'test')

  db_result = Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  games.each do |tc|
    puts '=' * 60

    puts "Game: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = Game.create_game(tc)
    puts 'Result of game creation:'
    puts create_result.inspect

    puts
  end

  moves.each do |move|
    Database.insert(
      Database::MOVE_TABLE,
      move.map{|k, v| k.to_s},
      move.map{|k, v| v}
    )
  end

  game_result = Database.execute_query <<-HERE
    SELECT id,player1,player2,status,turn,board FROM #{Database::GAME_TABLE}
  HERE
  board_result = Database.execute_query <<-HERE
    SELECT id,width,height,boardstring FROM #{Database::BOARD_TABLE}
  HERE

  puts 'Game table after creating games:'
  puts game_result.inspect
  puts 'Board table after creating games:'
  puts board_result.inspect
  puts

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"

    load_result = Game.load_game(tc)
    puts 'Result of game load:'
    puts load_result

    puts
  end
end
