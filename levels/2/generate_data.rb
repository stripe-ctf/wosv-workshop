#!/usr/bin/env bundle exec ruby

require 'rubygems'
require 'bundler/setup'

require 'json'
require 'securerandom'
require 'sqlite3'

class DataGenerator
  def self.random_string(length=7)
    length.times.map{('a'.ord + SecureRandom.random_number(26)).chr}.join('')
  end

  def self.main(basedir, level03, proof, plans)
    puts 'Generating users.rb'

    db = SQLite3::Database.new(File.join(basedir, 'users.db'))
    db.execute('DROP TABLE IF EXISTS users')
    db.execute(<<-EOM
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username VARCHAR(255),
  password_hash VARCHAR(255),
  salt VARCHAR(255)
)
EOM
    )

    id = 1
    dict = {}

    list = [['bob', level03], ['eve', proof], ['mallory', plans]]
    list.shuffle!

    list.each do |username, secret|
      password = random_string()
      salt = random_string()
      password_hash = Digest::SHA256.hexdigest(password + salt)
      puts "- Adding #{username}"

      db.execute(
        "INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?)",
        [username, password_hash, salt]
      )

      dict[id] = secret
      id += 1
    end

    puts 'Generating secrets.json'
    File.open(File.join(basedir, 'secrets.json'), 'w') do |f|
      JSON.dump(dict, f)
    end

    puts 'Generating entropy.dat'
    File.open(File.join(basedir, 'entropy.dat'), 'w') do |f|
      f.write(SecureRandom.random_bytes(24))
    end
  end
end

if $0 == __FILE__
  if ARGV.length != 4
    puts "Usage: #{__FILE__} <basedir> <level03> <proof> <plans>"
    exit(1)
  end

  DataGenerator.main(*ARGV)
end
