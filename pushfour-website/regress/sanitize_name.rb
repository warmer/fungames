#!/usr/bin/env ruby

require_relative '../lib/common.rb'

include Pushfour::Website::Common

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
  puts "#{name.inspect} sanitizes to #{sanitized_name(name).inspect}"
end
