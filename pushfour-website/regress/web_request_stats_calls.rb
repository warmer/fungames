#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/player.rb'
require_relative '../lib/game.rb'

include Pushfour::Website

tcs = [
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      # this game will end with a victory for player1
      {player: 1, x: 0, y: 0},
      {player: 2, x: 1, y: 0},
      {player: 1, x: 0, y: 1},
      {player: 2, x: 1, y: 1},
      {player: 1, x: 0, y: 2},
      {player: 2, x: 1, y: 2},
      {player: 1, x: 0, y: 3},
    ],
  },
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      # this game will end in a stalemate
      {player: 1, x: 0, y: 0},
      {player: 2, x: 1, y: 0},
      {player: 1, x: 0, y: 1},
      {player: 2, x: 1, y: 1},
      {player: 1, x: 1, y: 2},
      {player: 2, x: 0, y: 2},
      {player: 1, x: 1, y: 3},
      {player: 2, x: 0, y: 3},
      {player: 1, x: 2, y: 0},
      {player: 2, x: 3, y: 0},
      {player: 1, x: 2, y: 1},
      {player: 2, x: 3, y: 1},
      {player: 1, x: 3, y: 2},
      {player: 2, x: 2, y: 2},
      {player: 1, x: 3, y: 3},
      {player: 2, x: 2, y: 3},
    ],
  },
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [],
  },
  { game: {height: 4, width: 4, obstacles: 0, creator: 1, opponent: 2, first_move: 0, user_id: 1},
    moves: [
      # this game will remain active since there is no win or stalemate
      {player: 1, x: 0, y: 0},
    ],
  },

]
seed = 4

def test_path(path)
  puts "GET #{path}"
  res = get(path, false)
  puts "#{res.code} #{res.message}"
  puts "Response body: #{res.body}"
  puts "Location: /#{res['Location'].split('/', 4)[3]}" if res['Location']
  puts
end

Harness.run_test(mock_db: true, run_web: true) do
  Player.register(name: 'user1', password: 'test', password2: 'test')
  Player.register(name: 'user2', password: 'test', password2: 'test')

  game_ids = []
  paths = %w(/latest_stalemate /latest_victory /latest_active)

  paths.each { |path| test_path(path) }

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    tc = {rand_seed: seed}.merge(tc)

    create_result = Game.create_game(tc[:game])
    game_id = create_result[:game]
    game_ids << game_id

    tc[:moves].each {|move| Game.make_move(move.merge(game_id: game_id)) }

    puts

    paths.each { |path| test_path(path) }
  end
  puts '=' * 60

  puts 'The first game is won by the first player'
  puts 'The second game is a stalemate'

  game_ids.each do |game_id|
    path = "/game_details/#{game_id}"
    puts "GET #{path}"
    res = get path
    puts res
    puts

    path = "/game_info?game_id=#{game_id}"
    puts "GET #{path}"
    res = get path
    puts res
    puts

  end

  [1, 2].each do |player_id|
    path = "/get_games?player_id=#{player_id}"
    puts "GET #{path}"
    res = get path
    puts res
    puts
  end

end
