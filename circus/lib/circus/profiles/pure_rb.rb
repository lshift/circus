require File.expand_path('../ruby_base', __FILE__)

module Circus
  module Profiles
    class PureRb < RubyBase
      PURERB_APP_PROPERTY='purerb-app'
      
      # Checks if this is a pure ruby application. Will accept the application if it 
      # has a file named <name>.rb, or has a 'purerb-app' property describing the entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? PURERB_APP_PROPERTY
        return File.exists?(File.join(dir, "#{name}.rb"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @rb_script = props[PURERB_APP_PROPERTY] || "#{name}.rb"
      end
      
      # The name of this profile
      def name
        "pure-rb"
      end

      # Just run the script in development
      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec ruby #{@rb_script}
          EOT
        end
      end

      # Install our gems and then run in deployment
      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec ruby #{@rb_script}
          EOT
        end
      end
    end
    
    PROFILES << PureRb
  end
end