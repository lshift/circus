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
  end
end