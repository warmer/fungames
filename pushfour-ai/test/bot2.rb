#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

ai = PushfourAI::AI.new(1006, dynamic_depth: false, search_depth: 4)

puts 'Run the AI'
ai.run

puts 'AI finished running'

