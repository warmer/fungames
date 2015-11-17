require 'sinatra'
require 'json'
require 'pp'

PATH_ROOT = '/'

URL = {
  index: PATH_ROOT,
}

class GameWebsite < Sinatra::Base
  def locals(overrides = {})
    locals = {
    }

    locals.merge(overrides)
  end

  def url(page, opts = {})
    url_replace(URL, page, opts)
  end

  get URL[:index] do

    erb :index, locals: locals
  end
end
