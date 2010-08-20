require File.expand_path('../make_base', __FILE__)

module Circus
  module Profiles
    class Shell < MakeBase
      SHELL_APP_PROPERTY='shell-app'
      
      # Checks if this is a shell applcation. Will accept the application if it 
      # has a file named <name>.sh, or has a 'shell-app' property describing the entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? SHELL_APP_PROPERTY
        return File.exists?(File.join(dir, "#{name}.sh"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @sh_script = props[SHELL_APP_PROPERTY] || "#{name}.sh"
      end
      
      # The name of this profile
      def name
        "shell"
      end
      
      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec sh #{@sh_script}
          EOT
        end
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec sh #{@sh_script}
          EOT
        end
      end
    end
    
    PROFILES << Shell
  end
end