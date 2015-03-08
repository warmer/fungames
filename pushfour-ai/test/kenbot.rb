#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

ai = PushfourAI::AI.new(32, poll_delay: 5, search_depth: 4)

puts 'Run the AI'
ai.run

puts 'AI finished running'

