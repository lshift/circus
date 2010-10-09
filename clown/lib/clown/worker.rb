require 'net/http'
require 'fileutils'
require 'yaml'
require 'circus/external_util'

module Clown
  class Worker
    def initialize(config)
      @config = config
    end
    
    def deploy(name, url, config_url, logger)
      logger.info("Executing package deploy of: #{name}")

      if deployed?(name)
        logger.info("Undeploying up current version")
        deactivate_image(name, logger)
        cleanup_working_dir(name, logger)
      end

      return unless download_act(name, url, logger)
      return unless download_config(name, config_url, logger) unless config_url.empty?
      return unless env = prepare_working_dir(name, logger)
      if env[:persistent_run]
        return unless activate_image(name, logger)
        return unless await_service_startup(name, logger)
      else
        run_application(name, logger)
        cleanup_working_dir(name, logger)
      end
      
      logger.info("Done")
    end
    
    def undeploy(name, logger)
      logger.info("Executing package undeploy of: #{name}")
      
      return unless deactivate_image(name, logger)
      return unless cleanup_working_dir(name, logger)
      
      logger.info("Done")
    end

    def exec(name, command, logger)
      logger.info("Act #{name} executing #{command}")

      working_dir = mk_working_dir(name)
      unless File.exists? working_dir
        logger.info("Unknown act #{name}")
        return false
      end

      Circus::ExternalUtil.run_and_show_external(logger, 'Requested command', "#{working_dir}/with_env #{command}")
    end
    
    def reset(name, logger)
      logger.info("Resetting Act #{name}")
      deactivate_image(name, logger)
      activate_image(name, logger)
      
      logger.info('Done')
    end
    
    def configure(name, config_url, logger)
      logger.info("Execution configuration of: #{name}")

      download_config(name, config_url, logger)
      deactivate_image(name, logger)
      cleanup_working_dir(name, logger)
      prepare_working_dir(name, logger)
      activate_image(name, logger)

      logger.info("Done")
    end
    
    private
      def download_act(name, url, logger)
        target_file = mk_image_file(name)
        logger.info("Downloading #{url} to #{target_file}")
        
        # Ensure that the image dir exists
        FileUtils.mkdir_p(File.dirname(target_file))

        act_uri = URI.parse(url)
        case act_uri.scheme
          when nil
            # Assume that it is a file url
            FileUtils.cp(url, target_file)
          when 'http'
            File.open(target_file, 'wb') do |f|
              content = Net::HTTP.get(URI.parse(url))
              f.write(content)
            end
        end
        
        true
      end
      
      def download_config(name, config_url, logger)
        target_file = mk_config_file(name)
        logger.info("Downloading #{config_url} to #{target_file}")
        
        # Ensure that the image dir exists
        FileUtils.mkdir_p(File.dirname(target_file))

        # Download the content
        File.open(target_file, 'wb') do |f|
          content = Net::HTTP.get(URI.parse(config_url))
          f.write(content)
        end
        
        true
      end
      
      def prepare_working_dir(name, logger)
        image_file = mk_image_file(name)
        working_dir = mk_working_dir(name)
        log_working_dir = mk_log_working_dir(name)

        # Ensure we have a working directory, and a log directory
        FileUtils.mkdir_p(working_dir)
        FileUtils.mkdir_p(log_working_dir)

        # Phase 1
        # logger.info("Preparing First Phase Scripts")
        # write_script(working_dir, 'cleanup', format_cleanup_script(name, working_dir))

        logger.info("Expanding Image")
        act_dir = mk_act_dir(name, working_dir)
        FileUtils.mkdir_p(act_dir)
        result = `cd #{act_dir} && tar -xzf #{image_file} 2>&1`
        if $? != 0
          logger.error("Failed to expand image\n" + result)
          return false
        end
        
        logger.info("Securing Files")
        result = `cd #{act_dir} 2>&1 && chmod -R ugo-w . 2>&1 && chown -R root:root . 2>&1`
        if $? != 0
          logger.error("Failed to secure files\n" + result)
          return false
        end
        
        # Prepare config
        config_src = mk_config_file(name)
        apply_config = File.exists?(config_src)
        if apply_config
          logger.info("Preparing additional configuration")
          config_dir = File.join(working_dir, 'config')
          FileUtils.mkdir_p(config_dir)
          
          # Sniff the config file to see if it is a compressed archive
          file_type = `file -b --mime-type #{config_src}`
          if file_type == 'application/x-gzip'
            result = `tar -xzf #{config_src} -C #{config_dir}`
            if $? != 0
              logger.error("Failed to unpack configuration archive\n" + result)
              return false
            end
          else
            # Assume that we've just got a raw yaml file
            FileUtils.cp(config_src, File.join(config_dir, 'requirements.yaml'))
          end
        end

        # Phase 2
        logger.info("Preparing Scripts")
        env = build_environment(name, working_dir, apply_config, logger)
        write_script(working_dir, 'with_env', format_env_script(name, working_dir, env))
        write_script(working_dir, 'run', format_run_script(name, working_dir, env))
        write_script(log_working_dir, 'run', format_log_run_script(env))
        
        env
      end
          
      def cleanup_working_dir(name, logger)
        working_dir = mk_working_dir(name)
        cleanup_f = "#{working_dir}/cleanup"
              
        if File.exists? cleanup_f
          logger.info("Executing Cleanup")
          result = `#{cleanup_f} 2>&1`
          if $? != 0
            logger.error("Failed to execute cleanup script\n" + result)
            return false
          end
        end
        
        # Remove the working directory
        if File.exists? working_dir
          logger.info("Removing Working Directory")
          FileUtils.rm_rf(working_dir)
        end
        
        true
      end
      
      def activate_image(name, logger)
        working_target_dir = mk_working_dir(name)
        service_link = mk_service_link(name)
        
        logger.info("Activating Service")
        
        # Symlink the image into the /etc/services directory so that svscan will find it
        FileUtils.ln_s(working_target_dir, service_link, :force => true)
        
        true
      end
      
      def deactivate_image(name, logger)
        service_link = mk_service_link(name)
        working_dir = mk_working_dir(name)
        
        # Remove the symlink from the services dir
        if File.exists? service_link
          logger.info("Deactivating Service")
          FileUtils.rm(service_link)
        end 
        if File.exists?(File.join(working_dir, 'supervise'))
          res = `svc -ix #{working_dir}`
          if $? != 0
            logger.error("Failed to initiate service shutdown")
          end
          unless await_act_shutdown(name, logger)
            logger.error("Service did not shutdown")
          end
        end
        if File.exists?(File.join(working_dir, 'log', 'supervise'))
          res = `svc -ix #{working_dir}/log`
          if $? != 0
            logger.error("Failed to initiate service logger shutdown")
          end
          unless await_logger_shutdown(name, logger)
            logger.error("Service logger did not shutdown")
          end
        end
        
        true
      end
      
      def await_service_startup(name, logger)
        logger.info("Waiting for startup of #{name}")
        working_dir = mk_working_dir(name)
        
        (1..100).each do |i|
          `svok #{working_dir}`
          return true if $? == 0
          
          sleep 1
        end
        
        return false
      end

      def await_act_shutdown(name, logger)
        working_dir = mk_working_dir(name)
        await_service_shutdown(name, working_dir, logger)
      end
      def await_logger_shutdown(name, logger)
        working_dir = File.join(mk_working_dir(name), 'log')
        await_service_shutdown(name + ' logger', working_dir, logger)
      end
      
      def await_service_shutdown(name, working_dir, logger)
        logger.info("Waiting for shutdown of #{name}")

        (1..100).each do |i|
          `svc -ix #{working_dir}`
          `svok #{working_dir}`
          return true if $? != 0
          
          sleep 1
        end
        
        return false
      end
      
      def run_application(name, logger)
        working_dir = mk_working_dir(name)
        Circus::ExternalUtil.run_and_show_external(logger, 'Execute one-off application', "cd #{working_dir}; ./run")
      end
            
      def mk_image_file(name)
        File.join(@config.image_dir, "#{name}.act")
      end
      
      def mk_config_file(name)
        File.join(@config.image_dir, "#{name}.actcfg")
      end
      
      def mk_working_dir(name)
        File.join(@config.working_dir, name)
      end

      def mk_log_working_dir(name)
        File.join(mk_working_dir(name), 'log')
      end

      def mk_service_link(name)
        File.join('/etc/service', name)
      end

      def mk_act_dir(name, working_dir)
        File.join(working_dir, 'act', name)
      end
      
      private
        def deployed?(name)
          File.exists? File.join(@config.working_dir, name)
        end

        def write_script(working_dir, name, contents)
          fn = File.join(working_dir, name)
          File.open(fn, 'w') do |f|
            f.write(contents)
          end
          FileUtils.chmod(0755, fn)
        end
      
        def format_env_script(name, working_dir, env)
          act_dir = mk_act_dir(name, working_dir)

          template = <<-EOT
            #!/bin/sh

            set -e

            # Set HOME so applications that require it work
            export HOME=#{env[:home_dir]}

            # Run setup commands
            export EXECUTE_USER=#{env[:user]}
            #{env[:setup_cmds].join("\n")}

            # Set environment properties
            #{env[:props].map {|k,v| "export #{k}=#{v}"}.join("\n")}

            # Boot the child with restricted privileges
            cd #{act_dir}
            exec setuidgid $EXECUTE_USER $* 2>&1
          EOT
          cleanup_template(template)
        end

        def format_run_script(name, working_dir, env)
          act_dir = mk_act_dir(name, working_dir)
          act_run_script = File.join(act_dir, 'run')

          template = <<-EOT
            #!/bin/sh

            set -e

            exec #{working_dir}/with_env #{act_run_script} 2>&1
          EOT
          cleanup_template(template)
        end

        def format_log_run_script(env)
          template = <<-EOT
            #!/bin/sh

            exec setuidgid #{env[:user]} logger
          EOT
          cleanup_template(template)
        end
        
        def cleanup_template(template)
          template.lines.map { |l| l.strip }.join("\n")
          
          # lines = template.lines
          # remove_len = template.lines.first.index('#')
          # 
          # lines.map do |l|
          #   l[remove_len..-1]
          # end.join('')
        end

        def build_environment(name, working_dir, apply_config, logger)
          act_dir = mk_act_dir(name, working_dir)
          requirements_fn = File.join(act_dir, "requirements.yaml")
          config_requirements_fn = File.join(working_dir, 'config', 'requirements.yaml')

          env = {
            :user => @config.run_user,  # The user to run the act under
            :home_dir    => working_dir, # Default the home directory to the (read-only) working directory. Custom execution users can change this.
            :working_dir => working_dir, # The working dir being used (read-only for resources) 
            :props => {},               # System properties to run with
            :setup_cmds => [],          # Commands to run when setting up env
            :persistent_run => false,   # Whether the application needs to be made runnable persistently, or just executed once
          }
          if File.exists?(requirements_fn)
            resource_data = YAML.load(File.read(requirements_fn))
          else
            resource_data = {}
          end
          if File.exists?(config_requirements_fn)
            logger.info("Applying additional configuration properties")
            Resources.apply_config_resources(resource_data, YAML.load(File.read(config_requirements_fn)))
          end
          Resources.update_env(@config, name, resource_data, env, logger)
          
          env
        end
  end
end