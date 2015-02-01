#!/usr/bin/env ruby

require_relative '../common.rb'

game_strings = [
  '+,+#++++++r#++b+#++rb+,4,5,2,rb,r',
]
game_strings.each do |game_string|
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
  game.board.xy.each do |row|
    puts "    #{row}"
  end
  puts "game.board.open_blocks #{game.board.open_blocks}"
  puts "game.board.movable_blocks #{game.board.movable_blocks}"
  puts

  move = game.board.movable_blocks[0]
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
  game.board.xy.each do |row|
    puts "    #{row}"
  end
  puts "game.board.open_blocks #{game.board.open_blocks}"
  puts "game.board.movable_blocks #{game.board.movable_blocks}"
  puts
end
