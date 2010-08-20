require 'circus/agents/agent'

module Clown
  class XMPP < Circus::Agents::Agent
  
    def initialize(connection, worker)
      super(connection)
      
      @worker = worker
    end
    
    command 'deploy' do |params, logger|
      EM.defer do
        begin
          name, url = params.required('name', 'url')

          @worker.deploy(name, url, logger)
          logger.complete
        rescue
          puts "Failed to execute deployment - " + $!, $@
          logger.failed($!.to_s)
        end
      end
    end
    
    command 'undeploy' do |params, logger|
      EM.defer do
        begin
          name = params.required('name')
          
          @worker.undeploy(name, logger)
          logger.complete
        rescue
          puts "Failed to execute undeployment - " + $!, $@
          logger.failed($!.to_s)
        end
      end
    end

    command 'exec' do |params, logger|
      EM.defer do
        begin
          name, command = params.required('name', 'command')
          result = @worker.exec(name, command, logger)
          if result
            logger.complete
          else
            logger.failed('execution failed')
          end
        rescue
          logger.failed(e.message)
        end
      end
    end
  end
end