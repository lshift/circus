require File.expand_path('../base', __FILE__)

module Circus
  module Profiles
    class PythonBase < Base
      # Development preparation is the same as deployment
      def prepare_for_dev(logger, run_dir)
        prepare_for_deploy(logger, run_dir)
      end

      def prepare_for_deploy(logger, overlay_dir)
        # Build the virtualenv
        unless File.exists? "#{@dir}/vendor"
          return false unless run_external(logger, "Create virtualenv", "cd #{@dir}; virtualenv --no-site-packages vendor")
        end

        if has_depsfile?
          File.read(depsfile_fn).lines.each do |dep|
            return false unless run_external(logger, "Install dep #{dep}", 
                "cd #{@dir}; vendor/bin/easy_install -q \"#{dep.strip}\"")
          end

          return false unless run_external(logger, "Make virtualenv relocatable", "cd #{@dir}; virtualenv --relocatable vendor")
        end
        
        true
      end

      protected
        def depsfile_fn
          "#{@dir}/Pydeps"
        end

        def has_depsfile?
          File.exists? depsfile_fn
        end
    end
  end
end
