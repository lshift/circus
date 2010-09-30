require File.expand_path('../base', __FILE__)

module Circus
  module Profiles
    class MakeBase < Base
      # Development preparation is the same as deployment
      def prepare_for_dev(logger, run_dir)
        prepare_for_deploy(logger, run_dir)
      end

      def prepare_for_deploy(logger, overlay_dir)
        # Build the application
        if File.exists?(File.join(@dir, 'Makefile'))
          logger.info("Compiling #{@name}")
          run_external(logger, 'Compile application', "cd #{@dir}; make")
        end
      end
    end
  end
end