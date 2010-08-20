module Clown
  module Resources
    # Handles requesting a different executing user
    class ExecutionUser
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['execution-user']
          env[:user] = resource_data['execution-user']
        end
      end
    end

    RESOURCES << ExecutionUser
  end
end