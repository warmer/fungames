#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_string = '+,bbrbb##rrbrbrr+#bbrrrbbrrbrrbrr++brrrbr#brbbbbrbr+++#rbrrr++brbb+bb+br+rrrbrbbbrb,9,9,2,rb,b'
puts 'Game string:'
puts game_string
puts

ai = PushfourAI::AI.new(1000)
game = Pushfour.parse_game_string(game_string)

game.board.players.each do |player|
  score = ai.score(game.board, player, game.turn)
  puts "Score for player #{player}: #{score}"
end

move, score = ai.find_move(game)
puts "Move: #{move}"
puts "Score: #{score}"
