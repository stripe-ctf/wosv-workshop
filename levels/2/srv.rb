#!/usr/bin/env bundle exec ruby
#
# Welcome to the Secret Safe!
#
# - users.db stores authentication info with the schema:
#
# CREATE TABLE users (
#   id VARCHAR(255) PRIMARY KEY AUTOINCREMENT,
#   username VARCHAR(255),
#   password_hash VARCHAR(255),
#   salt VARCHAR(255)
# );
#
# - For extra security, the dictionary of secrets lives
#   data/secrets.json (so a compromise of the database won't
#   compromise the secrets themselves)

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sqlite3'

require_relative './generate_data'

class SecretSrv < Sinatra::Base
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

  # Generate test data when running locally
  data_dir = File.join(File.dirname(__FILE__), 'data')
  if !File.exist?(data_dir)
    Dir.mkdir(data_dir)
    DataGenerator.main(data_dir, 'BOB_PASSWORD (WINNER)', 'EVE_PASSWORD', 'MALLORY_PASSWORD')
  end

  secrets = JSON.parse(File.read(File.join((data_dir), 'secrets.json')))

  get '/' do
    user_id = session[:user_id]
    if user_id.nil?
      File.read('index.html')
    else
      secret = secrets[user_id.to_s]
      "Welcome back! Your secret is #{secret} <a href='./logout'>Log out</a>\n"
    end
  end

  post '/login' do
    username = params[:username]
    password = params[:password]

    return "Must provide username\n" if !username
    return "Must provide password\n" if !password

    # Fetch the username, password hash, and salt from the database
    db = SQLite3::Database.new(File.join(data_dir, 'users.db'))
    query = "SELECT id, password_hash, salt FROM users " +
            "WHERE username = '#{username}' LIMIT 1"
    res = db.execute(query)

    return "There's no such user #{username}!\n" if res.empty?
    user_id, password_hash, salt = res.first

    # Calculate whether the provided password was correct
    calculated_hash = Digest::SHA256.hexdigest(password + salt)

    if calculated_hash != password_hash
      return "That's not the password for #{username}!\n"
    else
      session[:user_id] = user_id
      redirect '/'
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end
end

def main
  SecretSrv.run!
end

if $0 == __FILE__
  main
  exit(0)
end
