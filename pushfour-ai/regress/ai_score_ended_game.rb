#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_string = '+,+++++++#++++#+++++rrrr++++br#+++++bbb+#+++++++++++++++++++++++++,8,8,2,rb,b'
puts 'Game string:'
puts game_string
puts

game = Pushfour::AI.parse_game_string(game_string)

ai = PushfourAI::AI.new(1000)

game.board.players.each do |player|
  score = ai.score(game.board, player, game.turn)
  puts "Score for player #{player}: #{score}"
end
