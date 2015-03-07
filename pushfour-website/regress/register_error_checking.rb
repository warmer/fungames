#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'

tcs = [
  {name: 'bob1', password: 'pass1', password2: 'pass2'},
  {name: 'bob2', password: 'pass1', password2: nil},
  {name: 'bob3', password: nil, password2: 'pass2'},
  {name: '', password: 'pass1', password2: 'pass1'},
  {name: nil, password: 'pass1', password2: 'pass1'},
  {name: 'bob4', password: nil, password2: nil},
  {name: 'bob(5)', password: 'pass1', password2: 'pass1'},
  {name: 'bob 6', password: 'pass1', password2: 'pass1'},
  {name: 'bob7\u0092', password: 'pass1', password2: 'pass1'},
  {name: 'bob8', password: 'pass1', password2: 'pass1'},
  {name: 'bob8', password: 'pass2', password2: 'pass2'},
]

Harness.run_test(mock_db: true) do
  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    reg_result = Pushfour::Registration.register(tc)
    puts reg_result.inspect

    db_result = Pushfour::Database.execute_query <<-HERE
      SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
    HERE

    puts db_result.inspect

    puts
  end

end
