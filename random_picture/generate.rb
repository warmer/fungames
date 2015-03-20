#!/usr/bin/env ruby

require 'chunky_png'
require 'pp'

x = (ARGV[0] || 230).to_i
y = (ARGV[1] || 230).to_i
file = ARGV[2] || File.expand_path(File.join(__FILE__, '../', 'default.png'))

png = ChunkyPNG::Image.new(x, y, ChunkyPNG::Color::TRANSPARENT)

pixels = []

movement = 32

pval = [rand(256), rand(256), rand(256)]

x.times do |col_num|
  row = []
  pval = pixels[col_num - 1][0] unless col_num == 0
  y.times do |row_num|
    unless col_num == 0
      prev_col = pixels[col_num - 1][row_num]
      prev_col.each_with_index do |val, idx|
        pval[idx] = (pval[idx] + val)/2
      end
    end
    # average the pixels from the previous pixel and the previous column
    nxt = []
    pval.each_with_index do |val, idx|
      nv = val + rand(movement) + 1 - movement/2
      nv = [[nv, 0].max, 255].min
      nxt[idx] = nv
    end
    pval = nxt
    row << nxt
  end
  pixels << row
end

x.times do |col_num|
  y.times do |row_num|
    px = pixels[col_num][row_num]
    png[col_num, row_num] = ChunkyPNG::Color.rgba(px[0], px[1], px[2], 255)
  end
end


puts "Saving #{x}x#{y} image to #{file}"
png.save(file, interlace: true)
