#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

ai = PushfourAI::AI.new(1006, dynamic_depth: false, poll_delay: 12, search_depth: 3)

puts 'Run the AI'
ai.run

puts 'AI finished running'

