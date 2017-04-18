#!/usr/bin/env/ruby

require './db'
require 'bcrypt'
require 'date'
require 'pry'

def self.rand_choice(alphabet, length)
  value = ''
  length.times{ value << alphabet.sample}
  return value
end

ALPHANUM = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.split('')
def self.rand_alphanum(length)
  return rand_choice(ALPHANUM, length)
end

def run(level_password)
  create_tables()
  add_users()
  add_waffles(level_password)
  add_logs()
end

def create_tables()
  WaffleCopter::DB.conn.create_table! :users do
    Fixnum :id, null: false, primary_key: true
    String :name, null: false, unique: true
    String :password, null: false
    TrueClass :premium, null: false
    String :secret, null: false
  end

  WaffleCopter::DB.conn.create_table! :waffles do
    String :name, null: false, primary_key: true
    TrueClass :premium, null: false
    String :confirm, null: false
  end

  WaffleCopter::DB.conn.create_table! :logs do
    Fixnum :user_id, null: false
    String :path, null: false
    String :body, text: true
    Time :date, null: false, default: Sequel::CURRENT_TIMESTAMP

    index :user_id, name: 'user_id'
    index :date, name: 'date'
  end
end

def add_users()
  add_user(1, 'larry', rand_alphanum(16), 1)
  add_user(2, 'randall', rand_alphanum(16), 1)
  add_user(3, 'alice', rand_alphanum(16), 0)
  add_user(4, 'bob', rand_alphanum(16), 0)
  add_user(5, 'ctf', 'password', 0)
end


def add_waffles(level_password)
  add_waffle('liege', 1, level_password)
  add_waffle('dream', 1, rand_alphanum(14))
  add_waffle('veritaffle', 0, rand_alphanum(14))
  add_waffle('chicken', 1, rand_alphanum(14))
  add_waffle('belgian', 0, rand_alphanum(14))
  add_waffle('brussels', 0, rand_alphanum(14))
  add_waffle('eggo', 0, rand_alphanum(14))
end

def add_logs
    gen_log(1, '/orders', {waffle: 'eggo', count: 10,
                           lat: 37.351, long: -119.827})
    gen_log(1, '/orders', {waffle: 'chicken', count: 2,                           
                          lat: 37.351, long: -119.827})
    gen_log(2, '/orders', {waffle: 'dream', count: 2,
                           lat: 42.39561, long: -71.13051},
                    DateTime.new(2007, 9, 23, 14, 38, 00))
    gen_log(3, '/orders', {waffle: 'veritaffle', count: 1,
                           lat: 42.376, long: -71.116})
end

def add_user(uid, username, password, premium)
  hashed =  BCrypt::Password.create(password) # bcrypt-ruby salts automatically!
  secret = rand_alphanum(14)
  data = {id: uid, name: username, password: hashed, premium: premium, secret: secret}
  WaffleCopter::DB.conn[:users].insert(data)
end

def get_user(uid)
  return WaffleCopter::DB.conn[:users][:id => uid]
end

def add_waffle(name, premium, confirm)
  data = {name: name, premium: premium, confirm: confirm}
  WaffleCopter::DB.conn[:waffles].insert(data)
end

def gen_log(user_id, path, params, date=nil)
    user = get_user(user_id)

    # generate signature using client library
    params[:user_id] = user_id
    body = URI.encode_www_form(params)
    sig = Digest::SHA1.hexdigest(user[:secret] + body)
    body += '|sig:' + sig

    # prepare data for insert
    data = {'user_id': user_id, 'path': path, 'body': body}

    data['date'] = date if date

    WaffleCopter::DB.conn[:logs].insert(data)
end

if __FILE__ == $0
  password = File.read('password.txt').strip
  run(password)
end