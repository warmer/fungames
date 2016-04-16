#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'

include Pushfour::Website

tcs = [
  {name: 'foo1', password: 'test'},
  {name: 'foo2', password: 'f00'},
  {name: 'foo3', password: '123'},
  {name: 'f004', password: 'test'},
  {name: '1235', password: 'test'},
  {name: '1236', password: '1236'},
  {name: '0x1237', password: '0x1237'},
]

Harness.run_test(mock_db: true) do
  tcs.each do |tc|
    puts "Test case: #{tc}"
    reg_result = Registration.register(
      name: tc[:name],
      password: tc[:password],
      password2: tc[:password])

    db_result = Database.execute_query <<-HERE
      SELECT name,passhash,id FROM #{Database::PLAYER_TABLE}
    HERE

    puts db_result.inspect

    login_result = Login.login(
      name: tc[:name],
      password: tc[:password])

    puts login_result.inspect
    puts
  end
end
