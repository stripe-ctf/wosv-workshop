#!/usr/bin/env/ruby

require 'sequel'
require 'sinatra'
require 'bcrypt'
require 'json'
require 'digest'

require './db'

module WaffleCopter
  class Server < Sinatra::Base
    set :environment, :production
    enable :sessions

    # Use persistent entropy file
    entropy_file = 'entropy.dat'
    unless File.exists?(entropy_file)
      File.open(entropy_file, 'w') do |f|
        f.write(OpenSSL::Random.random_bytes(24))
      end
    end
    set :session_secret, File.read(entropy_file)

    helpers do
      def json_response(resp, status_code=200)
        return [status_code, {'Content-Type' => 'application/json'}, resp.to_json]
      end

      def json_error(message, status_code)
        return json_response({'error': message}, status_code)
      end
    end

    def die(msg, view)
      @error = msg
      halt(erb(view))
    end

    before do
      @user = logged_in_user
    end

    def logged_in_user
      if session[:user]
        @username = session[:user]
        @user = DB.conn[:users][:name => @username]
      end
    end

    get '/' do
      if @user
        @waffles = get_waffles()
        @endpoint = request.base_url
        erb :home
      else
        erb :login
      end
    end

    get '/login' do
    end

    post '/login' do
      username = params[:name]
      password = params[:password]
      user = DB.conn[:users][:name => username]

      unless user.nil?
        password_match = (BCrypt::Password.new(user[:password]) == password)
      end
      unless user and password_match
        die('Could not authenticate. Perhaps you meant to register a new' \
            ' account? (See link below.)', :login)
      end

      session[:user] = user[:name]
      redirect '/'
    end

    post '/orders' do
      # we need the original POST body in order to check the hash, so we use raw body
      # instead of the params
      body = request.body.read.to_s

      # parse POST body
      begin
        raw_params, sig = parse_post_body(body)
      rescue BadRequest => e
        puts "failed to parse #{body.inspect}"
        return json_error(e.message, 400)
      end

      puts "raw params: #{raw_params.inspect}"

      begin
        params = Rack::Utils.parse_nested_query(raw_params)
      rescue Exception => e
        halt 400, "failed to parse #{body.inspect}"
      end

      puts "sig: #{sig.inspect}"

      # look for user_id
      user_id = params['user_id']
      if user_id.nil?
        puts 'user_id not provided'
        return json_error('must provide user_id', 401)
      end

      # check that signature matches
      unless verify_signature(user_id, sig, raw_params)
        return json_error("signature check failed", 401)
      end

      # all OK -- process the order
      log_api_request(params['user_id'], '/order', body)
      return process_order(params)
    end

    get '/logs/:id' do
      if @user
        @logs = get_logs(params['id'])
        erb :logs
      else
        erb :login
      end
    end

    def log_api_request(user_id, path, body)
      log = {user_id: user_id, path: path, body: body}
      DB.conn[:logs].insert(log)
    end

    def get_waffles()
      return WaffleCopter::DB.conn[:waffles].all
    end

    def get_logs(user_id)
      return WaffleCopter::DB.conn[:logs].where(user_id: user_id)
    end

    def verify_signature(user_id, sig, raw_params)
      # get secret token for uesr_id
      user = DB.conn[:users][id: user_id]

      if user.nil?
        puts "user #{user_id} does not exist"
        return false 
      end
      secret = user[:secret]

      h = Digest::SHA1.hexdigest(secret + raw_params)
      puts "computed signature #{h} for body  #{raw_params.inspect}"
      if h != sig
        puts 'Signature does not match'
        return false
      end
      return true
    end

    def parse_post_body(body)
      raw_params, _, sig = body.strip().rpartition('|sig:')
      if raw_params == ""
        halt 400, "Failed to parse body: #{body}"
      end
      return raw_params, sig
    end

    def process_order(params)
      # get user from database
      user = DB.conn[:users][id: params['user_id']]

      # collect query parameters
      if params.include?('waffle')
        waffle_name = params['waffle']
      else
        return json_error('must specify waffle', 400)
      end

      if params.include?('count')
        count = params['count']
      else
        return json_error('must specify count', 400)
      end

      lat, long = params['lat'].to_f, params['long'].to_f
      if lat.nil? or long.nil?
        return json_error('where would you like your waffle today?', 400)
      end

      if count.to_i < 1
        return json_error('count must be >= 1', 400)
      end

      # get waffle from database
      waffle = DB.conn[:waffles][name: waffle_name]
      if waffle.nil?
        return json_error("no such waffle: #{waffle_name}", 404)
      end

      if waffle[:premium] and not user[:premium]
        return json_error('that waffle requires a premium subscription', 402)
      end

      plural = count.to_i > 1 ? 's' : ''
      msg = "Great news: #{count} #{waffle_name} waffle#{plural} will soon be flying your way!"

      return json_response({success: true, message: msg, confirm_code: waffle[:confirm]})
    end

  end
end

if __FILE__ == $0
  WaffleCopter::Server.run!
end