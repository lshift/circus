require 'circus/agents/client'
require 'circus/agents/encoding'

module Circus
  class BoothClient < Circus::Agents::Client
    def initialize(connection, logger)
      super(connection)
      
      @logger = logger
    end
    
    def create_booth(booth, name, scm_type, scm_url)
      @connection.call(booth, 'Booth', 'Booth', 'create', {'name' => name, 'scm' => scm_type, 'scm_url' => scm_url}, @logger)
    end
    
    def admit(booth, booth_id, commit_id, patch_fn, acts)
      @connection.call(booth, 'Booth', 'Booth', 'admit', 
        {'app_id' => booth_id, 'commit_id' => commit_id, 'patch_fn' => patch_fn || '', 'acts' => acts.join(',')}, @logger)
    end
    
    def get_ssh_key(booth)
      @connection.call(booth, 'Booth', 'Booth', 'get_ssh_key', {}, @logger)
    end
  end
end