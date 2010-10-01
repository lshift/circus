require 'sequel'

DB = Sequel.connect(:adapter => 'postgres', :host => '/var/run/postgresql')

module Postgres
  class Worker
    def initialize(config)
      @config = config
    end

    def create_database(name, user, password, logger)
      # Ensure that we have an owner user
      if DB[:pg_user].where(:usename => user.downcase).count == 0
        logger.info("Creating database user #{user}")
          # TODO: Can't use ? substitution - need to validate username
        DB["CREATE USER #{user} WITH PASSWORD ?", password].first
      end

      # Ensure that we have the database
      if DB[:pg_database].where(:datname => name.downcase).count == 0
        logger.info("Creating database #{name}")

        DB["CREATE DATABASE #{name} WITH OWNER=#{user}"].first
      end

      "#{user}@#{`hostname`.strip}/#{name}"
    end
  end
end