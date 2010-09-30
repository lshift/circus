module Circus
  class ExternalUtil
    def self.run_external(logger, desc, cmd)
      res = `#{cmd} 2>&1`
      if $? != 0
        logger.error "#{desc} failed:"
        logger.error res
        false
      else
        true
      end
    end
    
    def self.run_and_show_external(logger, desc, cmd)
      IO.popen("#{cmd} 2>&1", 'r') do |pipe|
        while (line = pipe.gets)
          logger.info(line)
        end
      end
      
      true
    end
  end
end