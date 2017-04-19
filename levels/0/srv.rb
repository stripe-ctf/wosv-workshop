#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'sequel'
require 'sinatra'
require 'sqlite3'

module SecretSafe
  class SecretSrv < Sinatra::Base
    set :environment, :production

    def get_secrets(namespace)
      query = 'SELECT * FROM secrets WHERE key LIKE :namespace || ".%"'
      DB.conn.execute(query, arguments: {namespace: namespace}).to_a
    end

    get '/' do
      @namespace = params[:namespace]

      if @namespace
        @secrets = get_secrets(@namespace)
        erb :level00
      else
        erb :level00
      end
    end

    post '/' do
      @namespace = params[:namespace]
      @secret_name = params[:secret_name]
      @secret_value = params[:secret_value]

      query = 'INSERT INTO secrets (key, secret) VALUES (:namespace || "." || :name, :value)'
      DB.conn.execute(query, arguments: {namespace: @namespace, name: @secret_name, value: @secret_value}).to_a

      @secrets = get_secrets(@namespace)

      erb :level00
    end
  end

  module DB
    def self.db_file
      'level00.db'
    end

    def self.conn
      @conn ||= Sequel.sqlite(db_file)
    end

    def self.random_string(length=10)
      length.times.map{('0'.ord + rand(74)).chr}.join
    end

    def self.init
      return if File.exists?(db_file)
      File.umask(0066)

      # Set up the DB
      conn.create_table(:secrets) do
        String :key
        String :secret
      end

      # Set up the next level's secret
      query = 'INSERT INTO secrets (key, secret) VALUES (:namespace || "." || :name, :value)'
      DB.conn.execute(query, arguments: {namespace: random_string, name: 'secret', value: random_string(20)}).to_a
    end
  end
end

def main
  SecretSafe::DB.init
  SecretSafe::SecretSrv.run!
end

if $0 == __FILE__
  main
  exit(0)
end
