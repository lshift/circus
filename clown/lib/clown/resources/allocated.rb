require 'circus/agents/dbus_connection'
require 'circus/resource_allocator_client'

module Clown
  module Resources
    # Handles requesting a network allocated resources
    class Allocated
      def self.configurable_props
        ['allocations']
      end
      
      def initialize(config, logger)
        @config = config
        @logger = logger
      end

      def update_env(name, resource_data, env)
        if resource_data['allocations']
            # TODO: Support remote allocators
          connection = Circus::Agents::DBusConnection.new
          
          resource_data['allocations'].each do |alloc|
            client = Circus::ResourceAllocatorClient.new(connection, @logger, alloc['type'])
            client.allocate('local:', alloc).result
          end
        end
      end
    end

    RESOURCES << Allocated
  end
end