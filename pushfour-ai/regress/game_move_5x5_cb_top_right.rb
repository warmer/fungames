#!/usr/bin/env ruby

require_relative '../common.rb'

game_string = ['+,',
  '++',
  '++',
  ',2,2,2,rb,r'].join

puts 'Game string:'
puts game_string

game = Pushfour.parse_game_string(game_string)

puts '===== BEFORE MOVING ====='
puts 'From the parsed game string:'
puts "Game player turn: #{game.turn}"
puts 'Computed board:'
puts "  game.board.xy array:"
puts "  game.board.x: #{game.board.x}"
puts "  game.board.y: #{game.board.y}"
puts "  board players: #{game.board.players}"
Pushfour.print_board(game)
puts "game.board.movable_blocks #{game.board.movable_blocks}"
puts

move = [1, 0]
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
Pushfour.print_board(game)
puts "game.board.movable_blocks #{game.board.movable_blocks}"
puts

