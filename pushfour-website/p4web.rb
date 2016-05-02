require 'date'
require 'sinatra'
require 'json'
require 'pp'
require 'sqlite3'
require 'fileutils'

require_relative 'lib/common.rb'
require_relative 'lib/database.rb'
require_relative 'lib/registration.rb'
require_relative 'lib/login.rb'
require_relative 'lib/players.rb'

PATH_ROOT = '/'

URL = {
  full_game_details: PATH_ROOT + 'game_details/:id',
  player_game_list: PATH_ROOT + 'get_games',
  tournaments: PATH_ROOT + 'tournaments',
  tournament: PATH_ROOT + 'tournament/:id',
  game_info: PATH_ROOT + 'game_info',
  make_move: PATH_ROOT + 'make_move',
  make_game: PATH_ROOT + 'new_game',
  bot_move: PATH_ROOT + 'bot_move',
  register: PATH_ROOT + 'register',
  profile: PATH_ROOT + 'profile',
  players: PATH_ROOT + 'players',
  player: PATH_ROOT + 'player/:id',
  stats: PATH_ROOT + 'stats',
  games: PATH_ROOT + 'games',
  game: PATH_ROOT + 'game/:id',
  logout: PATH_ROOT + 'logout',
  login: PATH_ROOT + 'login',
  about: PATH_ROOT + 'about',
  index: PATH_ROOT + 'home',
}

class PushfourWebsite < Sinatra::Base
  include Pushfour::Website
  include Common

  configure do
    use Rack::Session::Pool, :expire_after => 2592000
    #enable :logging, :dump_errors, :raise_errors, :show_exceptions
    enable :logging
    disable :dump_errors, :show_exceptions, :raise_errors

    log_dir = File.join(settings.root, 'log/')
    FileUtils.mkdir_p(log_dir)

    @@profile_log_path = File.join(log_dir, "#{settings.environment}-profile.log")
    @@profile_log = File.new(@@profile_log_path, 'a+')
    @@profile_log.sync = true

    @@access_log_path = File.join(log_dir, "#{settings.environment}-access.log")
    @@access_log = File.new(@@access_log_path, 'a+')
    @@access_log.sync = true
    use Rack::CommonLogger, @@access_log
  end

  after do
    unless File.exist? @@profile_log_path
      @@profile_log.reopen(@@profile_log_path, 'a+')
      @@profile_log.sync = true
    end

    time = DateTime.now.new_offset(0).iso8601
    path = request.path_info
    stats = Database.profile_info.to_json
    @@profile_log.write("#{time} #{request.request_method} #{path} #{stats}\n")
    @@profile_log.flush
  end

  before do
    rotate_csrf unless session[:csrf]

    unless File.exist? @@access_log_path
      @@access_log.reopen(@@access_log_path, 'a+')
      @@access_log.sync = true
    end

    if !request.safe?
      # this is a bot API request which is validated differently
      if request.path_info =~ /^\/*bot_.*/ and params["api_key"]
        results = Players.for_key(params["api_key"])
        halt 403, results[:errors] unless results[:errors].empty?
        halt 403, 'Invalid API key' unless results[:player]

        @api_player = results[:player]
      else
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
  end

  error do
    'Something went wrong!'
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
    filtered = filter(params, [:game_id, :x, :y])
    player = session[:user_id]
    params = {player: player}.merge(filtered)
    results = Game.make_move(params)
    # the CSRF token needs to be sent back to the page so more moves
    # can be made without the client needing to refresh
    results[:csrf] = session[:csrf]
    results.to_json
  end

  post URL[:bot_move] do
    # @api_key should be populated by the before filter
    halt 403, 'Invalid API key' unless @api_player

    filtered = filter(params, [:game_id, :x, :y, :side, :channel])
    results = Game.make_move(filtered.merge(player: @api_player[:id]))

    results.to_json
  end

  get URL[:player_game_list] do
    filtered = filter(params, [:player_id])
    filtered = filtered.merge(player_turn: true)
    results = Game.list(filtered)
    games = results[:games].map{|g| g[:id]}

    games.sort.join(',')
  end

  get URL[:game_info] do
    game_string = ''
    filtered = filter(params, [:game_id])
    id = val_if_int(filtered[:game_id])
    game_string = Game.new(id: id).game_string || '' if id

    game_string
  end

  # page load requests

  get URL[:players] do
    filtered = filter(params, [:limit, :start])
    results = Players.player_list(filtered)

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
    filtered = filter(params, [:name, :password, :password2])
    results = Registration.register(filtered)
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
    filtered = filter(params, [:name, :password])
    results = Login.login(filtered)
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
    filtered = filter(params, [:height, :width, :obstacles, :creator, :opponent, :first_move])
    filtered = filtered.merge(user_id: session[:user_id])

    results = Game.create_game(filtered)


    if results[:errors].size == 0
      redirect to(url(:game, {id: results[:game]}))
    else
      results = results.merge(Players.player_list(exclude: session[:user_id]))
      erb :create_game, locals: locals(results)
    end
  end

  get URL[:full_game_details] do |id|
    opts = {game_id: id, user_id: session[:user_id]}
    results = Game.load_game(opts)
    results.to_json
  end

  get URL[:game] do |id|
    opts = {game_id: id, user_id: session[:user_id]}
    results = Game.load_game(opts)

    erb :game, locals: locals(results)
  end

  get URL[:games] do
    filtered = filter(params, [:start])
    results = Game.list(filtered)

    erb :games, locals: locals(results)
  end

  get URL[:profile] do
    redirect to(url(:index)) unless session[:user_id]
    player = Players.profile_for(session[:user_id])

    erb :profile, locals: locals(player: player)
  end

  get URL[:login] do

    erb :login, locals: locals
  end

  get '/' do
    redirect to(url(:index))
  end

  get URL[:about] do

    erb :about, locals: locals
  end

  get URL[:index] do

    erb :index, locals: locals
  end
end
