require 'circus/agents/client'

module Circus
  class ClownClient < Circus::Agents::Client
    def initialize(connection, logger)
      super(connection)
      
      @logger = logger
    end
    
    def deploy(node, name, act_url, config_url = nil)
      @connection.call(node, 'Clown', 'Clown', 'deploy', {'name' => name, 'url' => act_url, 'config_url' => config_url || ''}, @logger)
    end
    
    def configure(node, name, config_url)
      @connection.call(node, 'Clown', 'Clown', 'configure', {'name' => name, 'config_url' => config_url}, @logger)
    end
    
    def undeploy(node, name)
      @connection.call(node, 'Clown', 'Clown', 'undeploy', {'name' => name}, @logger)
    end
    
    def exec(node, name, cmd)
      @connection.call(node, 'Clown', 'Clown', 'exec', {'name' => name, 'command' => cmd}, @logger)
    end
  end
end