require File.expand_path('../base', __FILE__)
require 'fileutils'
require 'bundler/circus_util'

module Circus
  module Profiles
    class RubyBase < Base
      BUNDLER_TOOL=File.expand_path('../../../bundler/gem_cacher.rb', __FILE__)
      
      def initialize(name, dir, props)
        super(name, dir, props)
      end

      # Do basic gemfile preparation for dev. Don't override dev_run_script_content, since it is the
      # same as the deployment variant.
      def prepare_for_dev(logger, run_dir)
        if has_gemfile?
            # TODO: Correct behaviour if working in the presence of an existing bundler environment
          run_external(logger, 'gem installation', "cd #{@dir}; bundle check || bundle install")
        end
        
        true
      end

      def prepare_for_deploy(logger, overlay_dir)
        # Run the gem bundler if necessary
        if has_gemfile?
          logger.info("Bundling gems")
          return false unless run_external(logger, 'gem installation', "cd #{@dir}; bundle install")
          return false unless run_external(logger, 'gem caching', 
              "cd #{@dir}; ruby #{BUNDLER_TOOL} && rm Gemfile.lock && bundle install vendor/bundle")
        end
        
        if @props['package-cmds']
          @props['package-cmds'].each do |cmd|
            logger.info("Executing custom package command: #{cmd}")
            run_cmd = if has_gemfile? then "cd #{@dir}; bundle exec #{cmd}" else "cd #{@dir}; #{cmd}" end
            
            return false unless run_external(logger, 'packaging command: ' + cmd, run_cmd)
          end
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
