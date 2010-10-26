require 'fileutils'

module Booth
  module Repos
    # Booth support for Git push endpoints
    class Git < Base
      def self.accepts_id?(key)
        key == 'git'
      end
      def self.accepts_dir?(dir)
        File.exists?(File.join(dir, '.git'))
      end
      
      def initialize(config = {})
        super(config)
      end
      
      def create_application(name, repo_dir, url, config, logger)
        result = `(cd #{repo_dir}; git clone #{url} . 2>&1)`
        unless $? == 0
          FileUtils.rm_r repo_dir

          logger.error('Failed to clone repository: ' + result)
          return false
        end
        
        File.open(config_fn(repo_dir), 'w') do |f|
          YAML.dump(config, f)
        end
        
        true
      end
      
      def prepare(name, repo_dir, commit_id, patch_fn, logger)
        result = `(cd #{repo_dir} && git fetch 2>&1 && git reset --hard #{commit_id} 2>&1 && git submodule update -i 2>&1 && git clean -d -f -x 2>&1)`
        unless $? == 0
          if result.index("Could not parse object")
              logger.error("Failed to prepare repository. Have you pushed to the repository?")
              return false
          end
          logger.error('Failed to prepare repository: ' + result)
          return false
        end
        
        # Apply the patch if specified
        unless patch_fn.empty?
          logger.info("Applying patch #{patch_fn}")
          `(cd #{repo_dir} && patch -p1 <#{patch_fn})`
          unless $? == 0
            logger.error('Failed to apply patch repository')
            return false
          end
        end
        
        true
      end

      # Retrieves the target that has been associated with the repo
      def config_for(repo_dir)
        YAML.load(File.read(config_fn(repo_dir)))
      end

      private
        def config_fn(repo_dir)
          File.join(repo_dir, '.git', 'circus')
        end
    end
    
    PROVIDERS << Git
  end
end