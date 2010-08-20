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
        `(cd #{repo_dir}; git clone #{url} .)`
        unless $? == 0
          FileUtils.rm_r repo_dir

          logger.error('Failed to clone repository')
          return false
        end
        
        File.open(config_fn(repo_dir), 'w') do |f|
          YAML.dump(config, f)
        end
        
        true
      end
      
      def prepare(name, repo_dir, commit_id, patch_fn, logger)
        `(cd #{repo_dir} && git fetch && git reset --hard #{commit_id} && git clean -f -x)`
        unless $? == 0
          logger.error('Failed to prepare repository')
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