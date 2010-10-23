require 'json'

module Circus
  module Profiles
    # A Chef Stack provides the ability to trigger deployment of system packages and configuration.
    class ChefStack < Base
      CHEF_STACK_PROPERTY='chef-stack'
      
      # Checks if this is a chef stack applcation. Will accept the application if it 
      # has a file named stack.yaml, or has a 'chef-stack' property describing the entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? CHEF_STACK_PROPERTY
        return File.exists?(File.join(dir, "stack.yaml"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @stack_script = props[CHEF_STACK_PROPERTY] || "stack.yaml"
      end
      
      # The name of this profile
      def name
        "chef-stack"
      end
      
      def requirements
        reqs = super
        reqs['execution-user'] = 'root'
        reqs
      end
      
      def mark_for_persistent_run?
        false
      end
      
      # Stacks are not useful in development
      def supported_for_development?
        false
      end
      
      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec echo "Stacks cannot be run in development"
          EOT
        end
      end
      
      def prepare_for_deploy(logger, overlay_dir)
        # Generate a chef configuration file
        stack_config = YAML::load(File.read(File.join(@dir, @stack_script)))
        File.open(File.join(overlay_dir, 'stack.json'), 'w') do |f|
          f.write(stack_config.to_json)
        end
        File.open(File.join(overlay_dir, 'solo-stack.rb'), 'w') do |f|
          f << "cookbook_path File.expand_path('../cookbooks', __FILE__)"
        end
        
        true
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec chef-solo -c solo-stack.rb -j stack.json
          EOT
        end
      end
    end
    
    PROFILES << ChefStack
  end
end