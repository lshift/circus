#module Bundler
#  class Environment
    #def write_rb_lock
      # Disabled
    #end
#  end
#end

module Bundler
  module Source
    # Disable the use of System Gems
    class SystemGems
      def specs
        []
      end
    end
  end
end