require 'ostruct'
require 'yaml'

module Booth
  class Config
    ## Class meta-methods
    def self.required_opts
      @required_opts ||= []
    end
    def self.optional_opts
      @optional_opts ||= []
    end
    def self.sys_property_opts
      @sys_property_opts ||= {}
    end
    
    def self.process_opts(*names)
      if names.last.is_a? Hash
        names.last.each do |k,v|
          attr_reader k
          sys_property_opts[k] = v
        end
        
        attr_reader(*(names[0..-2]))
      else
        attr_reader(*names)
      end
    end
    def self.required_opt(*names)
      process_opts(*names)
    end
    def self.optional_opt(*names)
      process_opts(*names)
    end
    
    # XMPP configuration
    required_opt :jid, :password
    optional_opt :host, :port
    
    # Storage configuration
    required_opt :act_store => 'ACTSTORE_ROOT', :data_dir => 'DATA_DIR'
    
    # Build configuration
    required_opt :build_dir => 'BUILD_DIR'
    
    def initialize(fname)
      props = YAML::load_file(fname)
      props.each do |k, v|
        instance_variable_set("@#{k}".to_sym, v)
      end
      
      self.class.sys_property_opts.each do |opt, env_key|
        if ENV[env_key]
          instance_variable_set("@#{opt}".to_sym, ENV[env_key])
        end
      end
      
      # TODO: Validate configuration
    end
  end
end