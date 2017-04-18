#!/usr/bin/ruby

require 'sequel'
require 'securerandom'

module WaffleCopter
  module DB
    def self.db_file
      'wafflecopter.db'
    end

    def self.conn
      @conn ||= Sequel.sqlite(db_file)
    end
  end
end