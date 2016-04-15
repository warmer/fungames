#!/usr/bin/env ruby

require_relative '../common.rb'

game_strings = [
  '+,bbrbb##rrbrbrr+#bbrrrbbrrbrrbrr++brrrbr#brbbbbrbr+++#rbrrr++brbb+bb+br+rrrbrbbbrb,9,9,2,rb,b',
  '+,+#+++++++#++++#++r++,4,5,2,rb,r',
  '+,+#++++++r#++b+#++rb+,4,5,2,rb,r',
]
game_strings.each do |game_string|
  puts 'Game string:'
  puts game_string

  game = Pushfour::AI.parse_game_string(game_string)
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
