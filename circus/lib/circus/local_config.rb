require 'fileutils'

module Circus
  class LocalConfig
    def initialize(dir = '.')
      @dir = File.expand_path(dir)
      @is_new = true
      
      @store_fn = find_store_fn
      load!
    end
    
    def booths
      @state[:booths] ||= {}
    end
    
    def aliases
      @state[:aliases] ||= {}
    end
    
    def new?
      @is_new
    end
    
    def load!
      if File.exists? @store_fn
        @is_new = false
        @state = YAML::load(File.read(@store_fn))
      else
        @state = {}
      end
    end
    
    def save!
      FileUtils.mkdir_p(File.dirname(@store_fn))
      File.open(@store_fn, 'w') do |f|
        YAML::dump(@state, f)
      end
      @is_new = false
    end
    
    private
      def find_store_fn
        path = @dir
        fn = store_fn_for_dir(path)
        
        until File.exists? fn
          next_path = File.dirname(path)
            
          # If we've hit the root, then the filename will keep repeating. 
          return store_fn_for_dir(@dir) if path == next_path
          
          # Build for the next loop
          path = next_path
          fn = store_fn_for_dir(path)
        end
        
        fn
      end
      
      def store_fn_for_dir(dir)
        File.join(dir, '.circus/config')
      end
  end
end