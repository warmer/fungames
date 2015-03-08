#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/players.rb'

def pp_player_table
  db_result = Pushfour::Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
  HERE

  puts "#{'=' * 20} PLAYER TABLE #{'=' * 20}"
  puts db_result.inspect
  puts "#{'=' * 20}==============#{'=' * 20}"
end

tcs = [
  {start: nil, limit: nil},
  {start: 1, limit: nil},
  {start: nil, limit: 25},
  {start: 5, limit: 25},
  {start: 5, limit: 5},
  {start: '5', limit: '5'},
  {start: 28, limit: 5},
  {start: -1, limit: 5},
  {start: 1, limit: -1},
  {start: '-1', limit: '5'},
  {start: '1', limit: '-1'},
  {start: 1, limit: 5, exclude: 2},
  {start: 1, limit: 5, exclude: '2'},
  {start: 1, limit: 5, exclude: 6},
]

Harness.run_test(mock_db: true) do
  30.times do |i|
    reg_result = Pushfour::Registration.register(
      name: sprintf('foo%02d', i + 1),
      password: 'test',
      password2: 'test')
  end

  puts 'Initial state of the player table:'
  pp_player_table
  puts

  tcs.each do |tc|
    puts 'Test case:'
    puts tc.inspect
    list_result = Pushfour::Players.player_list(tc)

    puts 'Results returned:'
    puts list_result.inspect
    puts
  end

  puts 'Final state of the player table:'
  pp_player_table
end
