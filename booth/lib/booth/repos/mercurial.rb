require 'uri'

# Integration with Mercurial server

module Booth
  module Repos
    class Mercurial < Base
      def self.accepts_id?(key)
        key == 'hg' || key == 'mercurial'
      end
      def self.accepts_dir?(dir)
        File.exists?(File.join(dir, '.hg'))
      end
      
      def create_application(name, repo_dir, url, config, logger)
        # Ensure that we have a valid host key
        if url.start_with? 'ssh://'
          uri = URI.parse(url)
          
          logger.info("Retreiving host key for #{url}")
          res = `ssh-keyscan -p #{uri.port || 22} #{uri.host} >>#{ENV['HOME']}/.ssh/known_hosts 2>&1`
          if $? != 0
            logger.error("Failed to retrieve host key for #{url}: #{res}")
            return false
          end
        end
        
        result = `(cd #{repo_dir}; hg clone #{url} .)`
        unless $? == 0
          FileUtils.rm_r repo_dir

          logger.error("Failed to clone repository: #{result}")
          return false
        end
        
        # Ensure that the purge extension works
        File.open("#{repo_dir}/.hg/hgrc", 'a') do |f|
          f.write <<-EOT
[extensions]
hgext.purge=
          EOT
        end
        
        File.open(config_fn(repo_dir), 'w') do |f|
          YAML.dump(config, f)
        end
        
        true
      end
      
      def prepare(name, repo_dir, commit_id, patch_fn, logger)
        up_res = `(cd #{repo_dir} && hg pull && hg up -C #{commit_id} && hg purge)`
        unless $? == 0
          logger.error("Failed to prepare repository:\n#{up_res}")
          return false
        end
        
        # Apply the patch if specified
        unless patch_fn.empty?
          logger.info("Applying patch #{patch_fn}")
          patch_res = `(cd #{repo_dir} && patch -p1 <#{patch_fn})`
          unless $? == 0
            logger.error("Failed to apply patch to repository:\n#{patch_res}")
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
          File.join(repo_dir, '.hg', 'circus')
        end
    end
    
    PROVIDERS << Mercurial
  end
end