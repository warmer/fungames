#!/usr/bin/env ruby

require_relative '../lib/common.rb'

include Pushfour::Website::Common

tcs = [
  {password: 'bob'},
  {password: 'bob', salt: 'saltysalt', iterations: 1023},
  {password: 'bob', salt: 'saltysalt', iterations: 1024},
  {password: 'bob', salt: 'saltysalt'},
  {password: 'b.o.b', salt: 'saltysalt'},
]

tcs.each do |s|
  puts "Input           : #{s}"
  begin
    puts ">> Hash         : #{pw_hash(s.dup)}"
  rescue ArgumentError => e
    puts ">> ArgumentError: #{e.message}"
  end
  puts
end
