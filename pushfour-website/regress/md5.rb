#!/usr/bin/env ruby

require_relative '../common.rb'

include Pushfour::Common

strings = [
  'bob',
  'b.o.b',
]

strings.each do |s|
  puts "#{s} hashes to #{md5sum(s)}"
end
