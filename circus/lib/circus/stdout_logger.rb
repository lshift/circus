module Circus
  class StdoutLogger
    def info(msg)
      puts "INFO: #{msg}"
    end
    
    def error(msg)
      puts "ERROR: #{msg}"
    end
  end
end