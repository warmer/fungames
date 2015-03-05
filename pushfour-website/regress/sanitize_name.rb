#!/usr/bin/env ruby

require_relative '../common.rb'

include Pushfour::Common

names = [
  'bob',
  'bob1999',
  'bob,jan',
  '"bob"',
  'bob''bob',
  'BOB',
  'B_O_B',
  'B-o-b',
  'b.o.b',
  nil,
  '',
]

names.each do |name|
  puts "#{name} sanitizes to #{sanitized_name(name)}"
end
