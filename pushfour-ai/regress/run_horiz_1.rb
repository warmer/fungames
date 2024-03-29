#!/usr/bin/env ruby

require_relative '../common.rb'

game_string = ['+,',
  '++++++',
  '++++++',
  ',2,6,2,rb,r'].join

puts 'Game string:'
puts game_string

moves = [
  [0, 0], [3, 1],
  [1, 0], [2, 1],
  [2, 0], [1, 1],
  [3, 0], [0, 1],
]

game = Pushfour::AI.parse_game_string(game_string)

puts '===== BEFORE MOVING ====='
puts 'From the parsed game string:'
puts "Game player turn: #{game.turn}"
puts 'Computed board:'
puts "  game.board.xy array:"
puts "  game.board.x: #{game.board.x}"
puts "  game.board.y: #{game.board.y}"
puts "  board players: #{game.board.players}"
Pushfour::AI.print_board(game)
puts "game.board.movable_blocks #{game.board.movable_blocks}"
puts

moves.each do |move|
  puts "Move to #{move}"
  game.make_move(move[0], move[1])

  puts '===== AFTER MOVING ====='
  puts 'From the parsed game string:'
  puts "Game player turn: #{game.turn}"
  puts 'Computed board:'
  puts "  game.board.xy array:"
  puts "  game.board.x: #{game.board.x}"
  puts "  game.board.y: #{game.board.y}"
  puts "  board players: #{game.board.players}"
  Pushfour::AI.print_board(game)
  puts "game.board.movable_blocks #{game.board.movable_blocks}"
  puts
end
