#!/usr/bin/env ruby

require_relative '../common.rb'
require_relative '../ai.rb'

# track using hot lady
api_key = '182ce2c7ba27a1ebad158df0285e24da8f6930bbd73c985ebdf110bae5acc160'
ai = PushfourAI::AI.new(1, min_poll_delay: 5, poll_delay: 30, search_depth: 4, api_key: api_key)

puts 'Run the AI'
ai.run

puts 'AI finished running'

