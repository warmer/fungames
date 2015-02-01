#!/usr/bin/env ruby

require_relative '../common.rb'

Pushfour.send_move(1234, 1000, :top, 0, echo_params: true)
Pushfour.send_move(1234, 1000, :bottom, 1, echo_params: true)
Pushfour.send_move(1234, 1000, :left, 2, echo_params: true)
Pushfour.send_move(1234, 1000, :right, 3, echo_params: true)
