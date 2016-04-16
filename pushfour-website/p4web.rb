require 'sinatra'
require 'json'
require 'pp'
require 'sqlite3'

require_relative 'lib/common.rb'
require_relative 'lib/registration.rb'
require_relative 'lib/create_game.rb'
require_relative 'lib/make_move.rb'
require_relative 'lib/game_status.rb'
require_relative 'lib/login.rb'
require_relative 'lib/players.rb'

PATH_ROOT = '/'

URL = {
  full_game_details: PATH_ROOT + 'game_details/:id',
  tournaments: PATH_ROOT + 'tournaments',
  tournament: PATH_ROOT + 'tournament/:id',
  make_move: PATH_ROOT + 'make_move',
  make_game: PATH_ROOT + 'new_game',
  register: PATH_ROOT + 'register',
  profile: PATH_ROOT + 'profile',
  players: PATH_ROOT + 'players',
  player: PATH_ROOT + 'player/:id',
  stats: PATH_ROOT + 'stats',
  games: PATH_ROOT + 'games',
  game: PATH_ROOT + 'game/:id',
  logout: PATH_ROOT + 'logout',
  login: PATH_ROOT + 'login',
  index: PATH_ROOT,
}

class PushfourWebsite < Sinatra::Base
  include Pushfour::Website
  include Common

  use Rack::Session::Pool, :expire_after => 2592000

  before do
    rotate_csrf unless session[:csrf]

    if !request.safe?
      cookie_auth = request.cookies['auth_token']
      session_auth = session[:auth_token]

      form_ok = session[:csrf] == params[:csrf_token]
      cookie_ok = session_auth == cookie_auth

      unless form_ok && cookie_ok
        puts "Form ok? #{form_ok}"
        puts "Cookie ok? #{cookie_ok} [#{cookie_auth} not #{session_auth}]"
        rotate_csrf
        halt 403, erb(:error)
      end
      rotate_csrf
    end
  end

  def rotate_csrf
    session[:csrf] = SecureRandom.hex(32)
    session[:auth_token] = session[:csrf]

    response.set_cookie 'auth_token', {
      value: session[:auth_token],
      expires: Time.now + (24 * 60 * 60),
      path: '/',
      httponly: true,
    }
  end

  def locals(overrides = {})
    locals = {
    }

    locals.merge(overrides)
  end

  def url(page, opts = {})
    url_replace(URL, page, opts)
  end

  # AJAX requests

  post URL[:make_move] do
    raw_params = filter(params, [:game_id, :x, :y])
    player = session[:user_id]
    params = {player: player}.merge(raw_params)
    results = Pushfour::Website.make_move(params)
    # the CSRF token needs to be sent back to the page so more moves
    # can be made without the client needing to refresh
    results[:csrf] = session[:csrf]
    results.to_json
  end

  # page load requests

  get URL[:players] do
    raw_params = filter(params, [:limit, :start])
    results = Players.player_list(raw_params)

    erb :players, locals: locals(results)
  end

  get URL[:player] do |player_id|
    player_id = player_id.to_i
    error = player = nil

    if player_id > 0
      player = Players.info_for(player_id)
      error = 'Player not found' unless player
    else
      error = 'Player not found'
    end

    errors = []
    errors << error if error

    erb :player, locals: locals(player: player, errors: errors)
  end

  post URL[:register] do
    raw_params = filter(params, [:name, :password, :password2])
    results = Registration.register(raw_params)
    if results[:errors].size == 0
      redirect to(URL[:login])
    else
      erb :register, locals: locals(results)
    end
  end

  get URL[:register] do
    erb :register, locals: locals
  end

  post URL[:login] do
    raw_params = filter(params, [:name, :password])
    results = Login.login(raw_params)
    if results[:errors].size == 0
      session[:user_id] = results[:id]
      session[:login_name] = results[:name]
      redirect to(URL[:index])
    else
      erb :login, locals: locals(results)
    end
  end

  get URL[:logout] do
    session[:user_id] = nil
    session[:login_name] = nil
    redirect to(URL[:index])
  end

  get URL[:make_game] do
    # for now, only logged-in players can make games
    redirect to(URL[:login]) if session[:user_id].nil?

    results = Players.player_list(exclude: session[:user_id])

    erb :create_game, locals: locals(results)
  end

  post URL[:make_game] do
    raw_params = filter(params, [:height, :width, :obstacles, :creator, :opponent, :first_move])
    raw_params = raw_params.merge(user_id: session[:user_id])

    results = Pushfour::Website.create_game(raw_params)


    if results[:errors].size == 0
      redirect to(url(:game, {id: results[:game]}))
    else
      results = results.merge(Players.player_list(exclude: session[:user_id]))
      erb :create_game, locals: locals(results)
    end
  end

  get URL[:full_game_details] do |id|
    opts = {game_id: id, user_id: session[:user_id]}
    results = Pushfour::Website.load_game(opts)

    results.to_json
  end

  get URL[:game] do |id|
    opts = {game_id: id, user_id: session[:user_id]}
    results = Pushfour::Website.load_game(opts)

    erb :game, locals: locals(results)
  end

  get URL[:games] do
    raw_params = filter(params, [:start])
    results = Pushfour::Website.list(raw_params)

    erb :games, locals: locals(results)
  end

  get URL[:login] do

    erb :login, locals: locals
  end

  get URL[:index] do

    erb :index, locals: locals
  end
end
