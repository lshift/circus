require 'circus/agents/client'
require 'circus/agents/encoding'
require 'json'

module Circus
  # Client used to speak to resource allocation components.
  class ResourceAllocatorClient < Circus::Agents::Client
    def initialize(connection, logger, allocator_obj)
      super(connection)
      
      @logger = logger
      @allocator_obj = allocator_obj
    end
    
    def allocate(allocator, spec)
      @connection.call(allocator, @allocator_obj, 'ResourceAllocator', 'allocate', {'spec' => spec.to_json}, @logger)
    end
  end
end