#!/usr/bin/env ruby

require_relative '../common.rb'

game_string = ['+,',
  '++++++++',
  '++++++++',
  '++++++++',
  '++++++++',
  '++++++++',
  '++++++++',
  '++++++++',
  '++++++++',
  ',8,8,2,rb,r'].join

puts 'Game string:'
puts game_string

moves = [
  [0, 0], [7, 7],
  [0, 1], [7, 6],
  [1, 0], [6, 7],
  [1, 1], [6, 6],

  [0, 2], [7, 5],
  [2, 0], [5, 7],
  [2, 1], [5, 6],
  [1, 2], [6, 5],
  [2, 2], [5, 5],

  [0, 3], [7, 4],
  [3, 0], [4, 7],
  [1, 3], [6, 4],
  [3, 1], [4, 6],
  [2, 3], [5, 4],
  [3, 2], [4, 5],
  [3, 3], [4, 4],
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
