#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'

Harness.run_test(mock_db: true) do
  reg_result = Pushfour::Registration.register(
    name: 'foo',
    password: 'test',
    password2: 'test')

  db_result = Pushfour::Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  login_result = Pushfour::Login.login(
    name: 'foo',
    password: 'test')

  puts login_result.inspect
end
