require 'bundler'
Bundler.require

require 'resque/tasks'

task :environment do
  require './app/initialize'
end

task 'resque:setup' => :environment

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
