require 'fileutils'

module Clown
  module Resources
    # Handles assignment
    class SysProp
      def self.configurable_props
        ['system-properties']
      end
      
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['system-properties']
          resource_data['system-properties'].each do |key,value|
            env[:props][key] = value
          end
        end
      end
    end

    RESOURCES << SysProp
  end
end