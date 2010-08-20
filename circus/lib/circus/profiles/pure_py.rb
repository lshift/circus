require File.expand_path('../python_base', __FILE__)

module Circus
  module Profiles
    class PurePy < PythonBase
      PUREPY_APP_PROPERTY='purepy-app'
      
      # Checks if this is a pure python application. Will accept the application if it 
      # has a file named <name>.py, or has a 'purepy-app' property describing the entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? PUREPY_APP_PROPERTY
        return File.exists?(File.join(dir, "#{name}.py"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @py_script = props[PUREPY_APP_PROPERTY] || "#{name}.py"
      end
      
      # The name of this profile
      def name
        "pure-py"
      end

      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec vendor/bin/python #{@py_script}
          EOT
        end
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec vendor/bin/python #{@py_script}
          EOT
        end
      end
    end
    
    PROFILES << PurePy
  end
end
