module Clown
  module Resources
    RESOURCES = []

    def self.update_env(config, name, resource_data, env, logger)
      RESOURCES.each do |r_clazz|
        r = r_clazz.new(config, logger)
        r.update_env(name, resource_data, env)
      end
    end
    
    def self.apply_config_resources(base, config)
      configurable = RESOURCES.map do |r_clazz| 
        if r_clazz.respond_to? :configurable_props
          r_clazz.configurable_props
        else
          []
        end
      end.flatten.uniq
      
      configurable.each do |prop|
        if config[prop]
          if config[prop].is_a? Array
            (base[prop] ||= []).concat(config[prop])
          elsif config[prop].is_a? Hash
            (base[prop] ||= {}).merge!(config[prop])
          end
        end
      end
    end
    
    def self.merge_config_lists
    end
  end
end

require File.expand_path('../resources/execution_user', __FILE__)
require File.expand_path('../resources/local_file_storage', __FILE__)
require File.expand_path('../resources/allocated', __FILE__)
require File.expand_path('../resources/own_dbus_service', __FILE__)
require File.expand_path('../resources/sysprop', __FILE__)
require File.expand_path('../resources/user_profile', __FILE__)
require File.expand_path('../resources/persistent_run', __FILE__)