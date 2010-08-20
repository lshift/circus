require 'circus/agents/agent'

module Postgres
  class XMPP < Circus::Agents::Agent

    def initialize(connection, worker)
      super(connection)
      
      @worker = worker
    end
      
    command 'createdb' do |params, logger|
      EM.defer {
        begin
          name, user, password = params.required('name', 'user', 'password')
          db_id = worker.create_database(name, user, password, logger)
          if db_id
            logger.complete(:db_id => db_id)
          else
            logger.failed('database creation failed')
          end
        rescue MissingParameterException => e
          logger.failed(e.message)
        rescue Exception
          logger.failed($!.to_s)
        end
      }
    end
  end
end