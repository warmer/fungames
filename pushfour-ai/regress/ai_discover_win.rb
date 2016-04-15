#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_string = '+,+#++++brr#+rb+#++rb+,4,5,2,rb,b'
puts 'Game string:'
puts game_string
puts

ai = PushfourAI::AI.new(1000, search_depth: 3, debug: false)
game = Pushfour::AI.parse_game_string(game_string)

Pushfour::AI.print_board(game)

game.board.players.each do |player|
  score = ai.score(game.board, player, game.turn)
  puts "Score for player #{player}: #{score}"
end

move, score = ai.find_move(game)
puts "Move: #{move}"
puts "Score: #{score}"
