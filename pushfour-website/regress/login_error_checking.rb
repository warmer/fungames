#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'

tcs = [
  {name: 'basic_user', password: 'incorrect'},
  {name: 'basic_user', password: nil},
  {name: 'basic_user', password: ''},
  {name: 'unknown_user', password: 'test'},
  {name: nil, password: 'test'},
  {name: 'basic_(user)', password: 'test'},
]

Harness.run_test(mock_db: true) do
  reg_result = Pushfour::Registration.register(
    name: 'basic_user',
    password: 'test',
    password2: 'test')

  db_result = Pushfour::Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  tcs.each do |tc|
    puts '=' * 60

    puts "Test case: #{tc.inspect}"
    login_result = Pushfour::Login.login(tc)
    puts login_result.inspect

    db_result = Pushfour::Database.execute_query <<-HERE
      SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
    HERE

    puts db_result.inspect

    puts
  end
end
