#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

game_strings = [
#  '+,+#++++++r#++b+#++rb+,4,5,2,rb,r',
  '+,++++++++b+++++r+++++r#+#++r++b+++++#,6,6,2,rb,b',
]

game_strings.each do |game_string|
  puts '=' * 40
  puts 'Game string:'
  puts game_string
  puts

  game = Pushfour::AI.parse_game_string(game_string)

  Pushfour::AI.print_board(game)

  3.times do |depth|
    depth += 1
    puts "# searching with depth #{depth} #"

    ai = PushfourAI::AI.new(1000, search_depth: depth)

    game.board.players.each do |player|
      score = ai.score(game.board, player, game.turn)
      puts "Score for player #{player}: #{score}"
    end

    move, score = ai.find_move(game)
    puts "Move: #{move}"
    puts "Score: #{score}"
  end
end
