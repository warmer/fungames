require 'sinatra'
require 'json'
require 'pp'
require 'sqlite3'

require_relative 'lib/common.rb'
require_relative 'lib/registration.rb'
require_relative 'lib/login.rb'

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
  'index' => PATH_ROOT,
}

class PushfourWebsite < Sinatra::Base
  include Pushfour::Common

  use Rack::Session::Pool, :expire_after => 2592000

  before do
    rotate_csrf unless session[:csrf]

    if !request.safe?
      form_ok = session[:csrf] == params[:csrf_token]
      cookie_ok = session[:csrf] == request.cookies['authenticity_token']
      unless form_ok && cookie_ok
        puts "Form ok? #{form_ok}"
        puts "Cookie ok? #{cookie_ok}"
        halt 403, erb(:error)
      end
      rotate_csrf
    end
  end

  def rotate_csrf
    session[:csrf] = SecureRandom.hex(32)

    response.set_cookie 'authenticity_token', {
      value: session[:csrf],
      expires: Time.now + (24 * 60 * 60),
      path: '/',
      httponly: true,
    }
  end

  def locals(overrides = {})
    locals = {
      # TODO: sinatra might have a mechanism for creating route-aware URLs...
      'url' => URL,
    }

    locals.merge(overrides)
  end

  get URL['players'] do

    erb :expenses, :locals => agg_locals(page_vars) do
      erb :expense_table, :locals => agg_locals(page_vars)
    end
  end

  post URL['register'] do
    raw_params = filter(params, [:name, :password, :password2])
    puts raw_params.inspect
    results = Pushfour::Registration.register(raw_params)
    if results[:errors].size == 0
      redirect to(URL['login'])
    else
      erb :register, :locals => locals(results)
    end
  end

  get URL['register'] do
    erb :register, :locals => locals
  end

  post URL['login'] do
    raw_params = filter(params, [:name, :password])
    puts raw_params.inspect
    results = Pushfour::Login.login(raw_params)
    if results[:errors].size == 0
      redirect to(URL['index'])
    else
      erb :login, :locals => locals(results)
    end
  end

  get URL['login'] do

    erb :login, :locals => locals
  end

  get URL['index'] do

    erb :index, :locals => locals
  end
end
