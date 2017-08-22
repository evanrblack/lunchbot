require 'bundler'
Bundler.require

ENV['RACK_ENV'] ||= 'development'
ENV['DATABASE_URL'] ||= 'sqlite://db/development.sqlite3'
ENV['REDIS_URL'] ||= 'redis://redis'

Sequel.default_timezone = :utc
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :validation_helpers
Sequel.connect(ENV['DATABASE_URL'])

APP_ROOT = File.expand_path(File.dirname(__FILE__))

MODEL_DIR = File.join(APP_ROOT, 'models/*.rb')
Dir[MODEL_DIR].each do |file|
  require file
end

JOB_DIR = File.join(APP_ROOT, 'jobs/*.rb')
Dir[JOB_DIR].each do |file|
  require file
end

Resque.redis = 'redis:6379'
