#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/player.rb'
require_relative '../lib/game.rb'

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

def cleaned_list(res)
  games = res[:games].map do |g|
    keys = g.keys.select do |k|
      [:id, :player1, :player2, :turn, :status, :board].include? k
    end
    game = {}
    keys.each do |k|
      game[k] = g[k]
    end
    game
  end
  games.sort! {|a, b| a[:id] <=> b[:id]}
  #{games: games, paged: res[:paged], start: res[:start], errors: res[:errors]}
  {games: games, errors: res[:errors]}
end

Harness.run_test(mock_db: true, run_web: true) do
  Player.register(
    name: 'user1',
    password: 'test',
    password2: 'test')
  Player.register(
    name: 'user2',
    password: 'test',
    password2: 'test')

  db_result = Database.execute_query <<-HERE
    SELECT name,passhash,apikey,id FROM #{Database::PLAYER_TABLE}
  HERE
  puts db_result.inspect

  api_keys = db_result.map{|r| r[2]}

  game_ids = []

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = Game.create_game(tc[:game])
    game_id = create_result[:game]
    game_ids << game_id
    puts 'Result of game creation:'
    puts create_result.inspect
    puts '#' * 60

    tc[:moves].each_with_index do |move, idx|
      puts "Move: #{move}"
      path = '/bot_move'
      params = {api_key: api_keys[move[:player] - 1], game_id: game_id, x: move[:x], y: move[:y]}
      puts "** POST #{path} with #{params}"
      res = post(path, params)
      puts res.body

      puts "**Game database dump: id,player1,player2,turn,status"
      db_result = Database.execute_query <<-HERE
        SELECT id,player1,player2,turn,status FROM #{Database::GAME_TABLE}
      HERE
      puts db_result.inspect

      [1,2,3].each do |player_id|
        puts '*' * 20
        game_list = Game.list(player_id: player_id)
        puts "**Full game list for #{player_id}: #{cleaned_list(game_list)}"
        game_list = Game.list(player_id: player_id, player_turn: true)
        puts "**Active game list for #{player_id}: #{cleaned_list(game_list)}"
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

    puts
  end
end
