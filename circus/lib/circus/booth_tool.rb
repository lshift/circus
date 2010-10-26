require 'circus/booth_client'
require 'circus/clown_client'
require 'circus/agents/encoding'
require 'tempfile'

module Circus
  class BoothTool
    def initialize(logger, config)
      @logger = logger
      @config = config
    end
    
    def connect(name, booth, options = {})
      # Detect the facets of the repository
      repo_type_clazz = if options[:repo_type] 
          Repos.find_repo_by_id(options[:repo_type])
        else
          Repos.find_repo_from_dir(File.expand_path('.'))
        end
      repo_type = repo_type_clazz.type_id
      repo_url = if options[:repo_url]
          options[:repo_url]
        else
          repo_helper = repo_type_clazz.new(File.expand_path('.'))
          repo_helper.repo_url
        end
      
      app_name = options[:app_name] || File.basename(File.expand_path('.'))

      @logger.info("Creating booth connection #{name} on #{booth} for #{repo_url} as #{app_name}")
      connection = ConnectionBuilder.new(options).build(booth)
      
      client = BoothClient.new(connection, @logger)
      booth_id = client.create_booth(booth, app_name, repo_type, repo_url).result
      
      @config.booths[name] = {
        :booth => booth, :booth_id => booth_id,
        :repo_type => repo_type,
        :target => options[:deploy_target] || booth
      }
    end
    
    def admit(name, apps, options)
      booth = get_booth_or_default(name)
      return unless booth

      repo_helper = Repos.find_repo_by_id(booth[:repo_type]).new(File.expand_path('.'))
      current_rev = repo_helper.current_revision

      unless current_rev
          @logger.error("Could not detect current repository version")
          return false
      end
      
      @logger.info("Starting admission into #{name} of version #{current_rev}")
      connection = ConnectionBuilder.new(booth).build(booth[:booth])
      # connection.configure_bg!(OpenStruct.new(booth))
      client = BoothClient.new(connection, @logger)
      apply_patch_fn = if options[:uncommitted]
        patch_fn = Tempfile.new('booth').path
        repo_helper.write_patch(patch_fn)
        
        connection.send_file(patch_fn)
      else
        ''
      end
      admitted = Circus::Agents::Encoding.decode(client.admit(booth[:booth], booth[:booth_id], current_rev, apply_patch_fn, apps).result)
      
      return if booth[:target] == 'none'
      clown_connection = ConnectionBuilder.new(options).build(booth[:target])
      clown_client = ClownClient.new(clown_connection, @logger)
      admitted.each do |name, url|
        @logger.info("Executing deployment of #{name} from #{url} to #{booth[:target]}")
        clown_client.deploy(booth[:target], name, url).result
      end
    end
      
    private
      def get_booth_or_default(name)
        unless name
          if @config.booths.count == 0
            @logger.error("No booths configured. Please configure a booth with 'connect' first.")
            return nil
          end
          
          if @config.booths.count > 1
            @logger.error("A booth name needs to be provided when multiple booths have been configured. " + 
                          "One of #{local_config.booths.keys.join(', ')} should be specified")
            return nil
          end

          name = @config.booths.keys.first
        end
        
        booth = @config.booths[name]
        unless booth
          @logger.error("No booth #{name} is configured. Configure it first with 'connect'.")
          return nil
        end
        
        booth
      end
  end
end