require 'bundler'
Bundler.require

require 'resque/tasks'
require 'resque/scheduler/tasks'
require 'yaml'

task :environment do
  require './app/initialize'
end

namespace :resque do
  task setup: :environment
  task setup_schedule: :setup do
    Resque.schedule = YAML.load_file(File.join(__dir__, '/config/resque_scheduler.yml'))
  end
  task scheduler: :setup_schedule
end

namespace :db do
  Sequel.extension :migration
  DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/development.sqlite3')

  desc 'Migrate the database'
  task :migrate do
    puts 'Migrating database...'
    Sequel::Migrator.run(DB, 'db/migrations')
  end

  desc 'Roll back the database'
  task :rollback do
    puts 'Rolling back database...'
    Sequel::Migrator.run(DB, 'db/migrations', relative: -1)
  end
end
