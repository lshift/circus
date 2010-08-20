require 'circus/agents/agent'

module Booth
  class XMPP < Circus::Agents::Agent
    def initialize(connection, worker)
      super(connection)
      
      @worker = worker
    end
  
    command 'create' do |params, logger|
      EM.defer do
        begin
          name, scm, scm_url, target = params.required('name', 'scm', 'scm_url', 'target')
        
          app_id = @worker.create_application(name, scm, scm_url, target, logger)
          if app_id
            logger.complete(:app_id => app_id)
          else
            logger.failed('application creation failed')
          end
        rescue Circus::Agents::MissingParameterException => e
          logger.failed(e.message)
        rescue
          logger.failed($!.to_s)
        end
      end
    end  

    command 'admit' do |params, logger|
      EM.defer do
        begin
          app_id, commit_id = params.required('id', 'commit_id')
          acts = params.optional('acts')

          result = @worker.admit(app_id, commit_id, logger, acts)
          if result
            logger.complete
          else
            logger.failed('admission failed')
          end
        rescue Circus::Agents::MissingParameterException => e
          logger.failed(e.message)
        rescue
          puts "Failed to admit application version - " + $!, $@
          
          logger.failed($!.to_s)
        end
      end
    end
  end
end