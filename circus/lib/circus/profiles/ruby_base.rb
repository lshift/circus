require File.expand_path('../base', __FILE__)
require 'fileutils'
require 'bundler/circus_util'

module Circus
  module Profiles
    class RubyBase < Base
      BUNDLER_TOOL=File.expand_path('../../../bundler/circus_bundler.rb', __FILE__)
      
      def initialize(name, dir, props)
        super(name, dir, props)
      end

      # No dev preparation required. Don't override dev_run_script_content, since it is the
      # same as the deployment variant.
      def prepare_for_dev(logger, run_dir); true; end

      def prepare_for_deploy(logger, overlay_dir)
        # Run the gem bundler if necessary
        if has_gemfile?
          logger.info("Bundling gems")
          run_external(logger, 'gem bundling', "cd #{@dir}; ruby #{BUNDLER_TOOL}")
        end
        
        true
      end
      
      def cleanup_after_deploy(logger, overlay_dir)
        Bundler::CircusUtil.unfix_external_paths(@dir)
      end

      def extra_dirs
        if has_gemfile?
          ["#{@dir}/.bundle"]
        else
          []
        end
      end

      protected
        def has_gemfile?
          File.exists? "#{@dir}/Gemfile"
        end

        # class LoggingShell
        #   def say(msg)
        #     puts msg
        #   end
        # end
    end
  end
end
