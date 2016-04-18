#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'
require_relative '../lib/create_game.rb'
require_relative '../lib/game_status.rb'
require_relative '../lib/make_move.rb'

include Pushfour::Website

tcs = [
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, x: 0, y: 0},
      {player: 2, x: 0, y: 1},
    ],
    last_move: 0,
  },
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      {player: 1, x: 0, y: 0},
      {player: 2, x: 0, y: 1},
    ],
    last_move: 0,
  },
]
seed = 4

Harness.run_test(mock_db: true, run_web: true) do
  Registration.register(
    name: 'user1',
    password: 'test',
    password2: 'test')
  Registration.register(
    name: 'user2',
    password: 'test',
    password2: 'test')

  db_result = Database.execute_query <<-HERE
    SELECT name,passhash,apikey,id FROM #{Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  game_ids = []

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = CreateGame.create_game(tc[:game])
    game_id = create_result[:game]
    game_ids << game_id
    puts 'Result of game creation:'
    puts create_result.inspect
    puts '#' * 60

    tc[:moves].each_with_index do |move, idx|
      puts "Move: #{move}"
      res = MakeMove.make_move(move.merge(game_id: game_id))
      puts "ERROR: #{res[:errors].join(',')}" unless res[:errors].empty?

      puts "**Game database dump: id,player1,player2,turn,status"
      db_result = Database.execute_query <<-HERE
        SELECT id,player1,player2,turn,status FROM #{Database::GAME_TABLE}
      HERE
      puts db_result.inspect

      [1,2,3].each do |player_id|
        puts '*' * 20
        game_list = GameStatus.list(player_id: player_id)
        puts "**Full game list for #{player_id}: #{game_list}"
        game_list = GameStatus.list(player_id: player_id, player_turn: true)
        puts "**Active game list for #{player_id}: #{game_list}"
        path = "/get_games?player_id=#{player_id}"
        puts "**GET #{path}"
        res = get path
        puts res
      end
      puts '*' * 30
      path = "/game_info?game_id=#{game_id}"
      puts "**GET #{path}"
      res = get path
      puts res
      puts '*' * 40
    end

    puts '#' * 60
    status = GameStatus.get_status(game_id: game_id, last_move: tc[:last_move])
    puts 'Get status result:'
    puts status.inspect

    puts
  end
end
