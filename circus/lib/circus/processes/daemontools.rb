module Circus
  module Processes
    # Support for working with Daemontools
    class Daemontools
      def pause_service(name, working_dir, logger)
        res = `svc -d #{working_dir}`
        if $? != 0
          logger.error("Failed to initiate service shutdown for #{name}")
          return
        end
        
        unless await_service_pause(name, working_dir, logger)
          logger.error("Service did not shutdown")
        end
      end
      
      def resume_service(name, working_dir, logger)
        res = `svc -u #{working_dir}`
        if $? != 0
          logger.error("Failed to initiate service startup for #{name}")
          return
        end
        
        unless await_service_startup(name, working_dir, logger)
          logger.error("Service did not resume")
        end
      end
      
      def await_service_startup(name, working_dir, logger)
        logger.info("Waiting for startup of #{name}")
        
        (1..100).each do |i|
          return true if is_service_running?(working_dir)
          sleep 1
        end
        
        return false
      end
      
      def await_service_pause(name, working_dir, logger)
        logger.info("Waiting for shutdown of #{name}")

        (1..5).each do |i|
          return true unless is_service_running?(working_dir)
          sleep 1
        end

        (1..100).each do |i|
          # Attempt a more brutal shutdown
          `svc -k #{working_dir}`
          
          return true unless is_service_running?(working_dir)
          sleep 1
        end
        
        return false
      end
      
      def is_service_running?(working_dir)
        res = `svstat #{working_dir}`
        $? == 0 && res.include?('up (pid')
      end
    end
  end
end