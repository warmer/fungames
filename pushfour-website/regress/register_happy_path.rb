#!/usr/bin/env ruby

require_relative '../test/harness.rb'
require_relative '../lib/database.rb'
require_relative '../lib/registration.rb'

Harness.run_test(mock_db: true) do
  reg_result = Pushfour::Registration.register(
    name: 'foo',
    password: 'test',
    password2: 'test')

  puts reg_result.inspect

  db_result = Pushfour::Database.execute_query <<-HERE
    SELECT name,passhash,id FROM #{Pushfour::Database::PLAYER_TABLE}
  HERE

  puts db_result.inspect

end
