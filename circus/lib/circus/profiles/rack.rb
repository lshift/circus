require File.expand_path('../ruby_base', __FILE__)

module Circus
  module Profiles
    class Rack < RubyBase
      RACKFILE_NAME='ruby-rackfile'
      
      # Checks if this is a rack applcation. Will accept the application if it has a config.ru, or if the
      # properties describe the location of an alternative rack entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? RACKFILE_NAME
        return File.exists?(File.join(dir, 'config.ru'))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @rackup_name = props[RACKFILE_NAME] || 'config.ru'
      end
      
      # The name of this profile
      def name
        "rack"
      end
      
      def dev_run_script_content
        shell_run_script do
          if @props['rackup-command'] == 'unicorn'
            <<-EOT
            cd #{@dir}
            exec bundle exec unicorn -p #{listen_port} #{@rackup_name}
            EOT
          else
            <<-EOT
            cd #{@dir}
            exec bundle exec thin -R #{@rackup_name} -p #{listen_port} start
            EOT
          end
        end
      end

      def deploy_run_script_content
        shell_run_script do
          if @props['rackup-command'] == 'unicorn'
            <<-EOT
            exec bundle exec unicorn -p #{listen_port} #{@rackup_name}
            EOT
          else
            <<-EOT
            exec bundle exec thin -R #{@rackup_name} -p #{listen_port} start
            EOT
          end
        end
      end
      
      # Describes the requirements of the deployed application. Rack applications automatically
      # have an environment system property applied for RACK_ENV and RAILS_ENV
      def requirements
        res = super

        res['system-properties'] ||= {}
        res['system-properties']['RACK_ENV'] = 'production'
        res['system-properties']['RAILS_ENV'] = 'production'
        
        res
      end
      
      private
        def listen_port
          @props['web-app-port'] || 3000
        end
    end
    
    PROFILES << Rack
  end
end