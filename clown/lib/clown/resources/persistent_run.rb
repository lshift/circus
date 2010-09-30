module Clown
  module Resources
    # Handles requesting a different executing user
    class PersistentRun
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['persistent-run']
          env[:persistent_run] = resource_data['persistent-run']
        end
      end
    end

    RESOURCES << PersistentRun
  end
end