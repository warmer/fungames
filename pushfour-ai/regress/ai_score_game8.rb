#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_strings = [
'+,++++++++++bb++++#+rb+++++rr#+++++r+b+++++#+++++++++++#++,7,8,2,rb,r',
]

depth = (ARGV[0] || 3).to_i

game_strings.each do |game_string|
  puts '=' * 40
  puts 'Game string:'
  puts game_string
  puts

  game = Pushfour::AI.parse_game_string(game_string)

  Pushfour::AI.print_board(game)

#  3.times do |depth|
  [depth].each do |depth|
    puts "# searching with depth #{depth} #"

    ai = PushfourAI::AI.new(1000, search_depth: depth)

    game.board.players.each do |player|
      score = ai.score(game.board, player, game.turn)
      puts "Score for player #{player}: #{score}"
    end

    move, score = ai.find_move(game)
    puts "Move: #{move}"
    puts "Score: #{score}"
  end
end
