require 'net/http'
require 'yaml'
require 'circus/external_util'

module Circus
  module Profiles
    PROFILES=[]
    
    # Base functionality for an Profile
    class Base
      def initialize(name, dir, props)
        @name = name
        @dir = dir
        @props = props
      end
      
      def package_base_dir?
        true
      end
      
      def extra_dirs
        []
      end

      def package_for_dev(logger, run_dir)
        return false unless prepare_for_dev(logger, run_dir)
        write_run_script(run_dir) do |f|
          f.write(dev_run_script_content.strip)
        end
      end

      def package_for_deploy(logger, run_dir)
        return false unless prepare_for_deploy(logger, run_dir)
        write_run_script(run_dir) do |f|
          f.write(deploy_run_script_content.strip)
        end
        File.open(File.join(run_dir, 'requirements.yaml'), 'w') do |f|
          f.write(requirements.to_yaml)
        end
      end
      
      def cleanup_after_deploy(logger, overlay_dir)
      end

      # Overriden by subclasses to specify the resources that they require. Defaults to a resource
      # hash provided in the act definition
      def requirements
        (@props['requirements'] || {}).dup
      end
      
      protected
        # Overriden by subclasses to handle development preparation. Defaults to the same as the deployment preparation.
        def prepare_for_dev(logger, run_dir)
          prepare_for_deploy(logger, run_dir)
        end

        # Overriden by classes to handle generating the run script content for development. 
        def dev_run_script_content
        end

        # Overriden by subclasses to handle deployment preparation
        def prepare_for_deploy(logger, run_dir)
          true
        end

        # Overriden by classes to handle generating the run script content for deployment.
        def deploy_run_script_content
        end

        def write_run_script(run_dir)
          File.open(File.join(run_dir, 'run'), 'w') do |f|
            yield f
          end
          File.chmod 0777, File.join(run_dir, 'run')
        end

        def shell_run_script
          <<-EOT
          #!/bin/sh

          #{yield}
          EOT
        end
        
        def write_dev_run_script(run_dir)
          write_run_script(run_dir) do |f|
            base_template = <<-EOT
              #!/bin/sh

              cd #{@dir}
            EOT
            
            f.write(base_template.lstrip)
            yield f
          end
        end        

        def write_deploy_run_script(run_dir)
          write_run_script(run_dir) do |f|
            base_template = <<-EOT
              #!/bin/sh

            EOT
            
            f.write(base_template.lstrip)
            yield f
          end
        end
        
        def run_external(logger, desc, cmd)
          ExternalUtil.run_external(logger, desc, cmd)
        end
    end
  end
end