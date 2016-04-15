#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'
require_relative '../lib/login.rb'

include Pushfour::Website

Harness.run_test(mock_db: true) do
  reg_result = Registration.register(
    name: 'foo',
    password: 'test',
    password2: 'test')

  db_result = Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

  login_result = Login.login(
    name: 'foo',
    password: 'test')

  puts login_result.inspect
end
