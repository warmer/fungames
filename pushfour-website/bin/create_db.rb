#!/usr/bin/env ruby

require_relative '../lib/database.rb'

if __FILE__ == $0
  puts 'Creating the database...'
  Pushfour::Website::Database.create
  puts 'Database created!'
end
