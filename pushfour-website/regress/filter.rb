#!/usr/bin/env ruby

require_relative '../lib/common.rb'

include Pushfour::Website::Common

strings = [
  'bob',
  'b.o.b',
]

strings.each do |s|
  puts "#{s} hashes to #{md5sum(s)}"
end
