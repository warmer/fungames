require 'sinatra'
require 'json'
require 'pp'
require 'sqlite3'

require_relative 'common.rb'

PATH_ROOT = '/'

URL = {
  'tournaments' => PATH_ROOT + 'tournaments',
  'tournament' => PATH_ROOT + 'tournament/:id',
  'register' => PATH_ROOT + 'register',
  'players' => PATH_ROOT + 'players',
  'player' => PATH_ROOT + 'player/:id',
  'games' => PATH_ROOT + 'games',
  'game' => PATH_ROOT + 'game/:id',
  'login' => PATH_ROOT + 'login',
}

class PushfourWebsite < Sinatra::Base
  include Pushfour::Common

  def locals(overrides = {})
    locals = {
      # TODO: sinatra might have a mechanism for creating route-aware URLs...
      'url' => URL,
    }

    locals.merge(overrides)
  end


  get PATH_ROOT do
    'Hello, world!'
  end

  get URL['players'] do

    erb :expenses, :locals => agg_locals(page_vars) do
      erb :expense_table, :locals => agg_locals(page_vars)
    end
  end

  post URL['register'] do
    raw_name = params['name']
    raw_password = params['password']
    raw_password2 = params['password2']

    results = form_actions.register(raw_name, raw_password, raw_password2)

    erb :register, :locals => locals(results)
  end

  get URL['register'] do

    erb :register, :locals => locals
  end

  get URL['login'] do

    erb :login, :locals => locals
  end
end
