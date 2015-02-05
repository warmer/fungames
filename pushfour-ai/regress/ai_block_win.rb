#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_string = '+,+#++++brr#+rb+#++rb+,4,5,2,rb,r'
puts 'Game string:'
puts game_string
puts

ai = PushfourAI::AI.new(1000, search_depth: 3)
game = Pushfour.parse_game_string(game_string)

puts 'Before move:'
Pushfour.print_board(game)

game.board.players.each do |player|
  score = ai.score(game.board, player, game.turn)
  puts "Score for player #{player}: #{score}"
end

move, score = ai.find_move(game)
puts "Move: #{move}"
puts "Score: #{score}"
