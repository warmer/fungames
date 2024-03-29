#!/usr/bin/env ruby

require_relative '../common.rb'

game_string = ['+,',
  '++',
  'rb',
  'rb',
  'rb',
  ',4,2,2,rb,r'].join

puts 'Game string:'
puts game_string

moves = [
  [0, 0],
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
puts "game.board.game_over #{game.board.game_over}"
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
  puts "game.board.game_over #{game.board.game_over}"
  puts
end
