module Booth
  module Repos
    class Base
      def initialize(config)
        @config = config
        
        @act_store = config.act_store
        @data_dir = config.data_dir
      end
    end
    
    PROVIDERS = []
  end
end