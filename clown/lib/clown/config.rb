require 'ostruct'

module Clown
  class Config
    ## Class meta-methods
    def self.required_opts
      @required_opts ||= []
    end
    def self.optional_opts
      @optional_opts ||= []
    end
    
    def self.required_opt(*names)
      attr_reader *names
#      required_opts += names
    end
    
    def self.optional_opt(*names)
      attr_reader *names
#      optional_opts += names
    end
    
    # XMPP configuration
    required_opt :jid, :password
    optional_opt :host, :port
    
    # Deployment configuration
    required_opt :image_dir, :working_dir, :run_user
    
    # Resources configuration
    required_opt :local_store_path, :dbus_system_path
    
    def initialize(fname)
      props = YAML::load_file(fname)
      props.each do |k, v|
        instance_variable_set("@#{k}".to_sym, v)
      end
      
      # TODO: Validate configuration
    end
  end
end