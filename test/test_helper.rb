ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] = 'sqlite://db/test.sqlite3'

require_relative '../app/initialize.rb'
