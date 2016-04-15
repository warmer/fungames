#!/usr/bin/env ruby

require_relative '../common.rb'

game_string = ['+,',
  'b#b+++++',
  '#r++++++',
  '+#++br++',
  '+++###++',
  '+rbr#b++',
  '++##++++',
  '++++++++',
  '++++++++',
  ',8,8,2,rb,b'].join

puts 'Game string:'
puts game_string

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

