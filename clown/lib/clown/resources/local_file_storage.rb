require 'fileutils'

module Clown
  module Resources
    # Handles assignment
    class LocalFileStorage
      def self.configurable_props
        ['local-file-storage']
      end
      
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['local-file-storage']
          resource_data['local-file-storage'].each do |dir|
            path = File.join(@config.local_store_path, name, dir)
            
            env[:setup_cmds] << "mkdir -p #{path}"
            env[:setup_cmds] << "chown $EXECUTE_USER #{path}"
            env[:props][dir] = path
          end
        end
      end
    end

    RESOURCES << LocalFileStorage
  end
end