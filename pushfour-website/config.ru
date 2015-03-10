require File.expand_path('../p4web.rb', __FILE__)

map '/' do
  run PushfourWebsite
end
