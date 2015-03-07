#!/usr/bin/env ruby

require_relative '../lib/common.rb'

include Pushfour::Common

urls = {
  a: '/a',
  b: '/b/:id',
  c: '/c/:id/:name',
}

tcs = [
  {page: :a, opts: nil},
  {page: :a, opts: {id: 1}},
  {page: :a, opts: {id: '1'}},
  {page: :b, opts: nil},
  {page: :b, opts: {id: 1}},
  {page: :b, opts: {id: '1'}},
  {page: :c, opts: nil},
  {page: :c, opts: {id: 1}},
  {page: :c, opts: {id: 1, name: 'bill'}},
  {page: :c, opts: {id: 1, name: 'bill', foo: 'bar'}},
  {page: :c, opts: {id: '1', name: 'bill', foo: 'bar'}},
]

puts 'URL sources:'
puts urls.inspect
puts

tcs.each do |tc|
  page = tc[:page]
  opts = tc[:opts]
  res = url_replace(urls, page, opts)

  puts '=' * 40

  puts "Page: #{page}; opts: #{opts.inspect}"
  puts "Resolves to: #{res}"
  puts

  unless opts
    puts 'opts was nil - calling without opts argument'
    res = url_replace(urls, page)
    puts "Page: #{page}"
    puts "Resolves to: #{res}"
    puts
  end
end
