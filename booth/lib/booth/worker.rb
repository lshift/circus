require 'circus'
require 'digest/md5'
require 'circus/clown_client'
require 'fileutils'

module Booth
  class Worker
    def initialize(connection, config)
      @connection = connection
      @config = config
      @data_dir = config.data_dir
    end
    
    def create_application(name, scm_id, scm_url, logger)
      app_id = generate_id(name, scm_url)
      repo_dir = File.join(@data_dir, app_id)
      
      unless File.exists? repo_dir
        provider_clazz = Booth::Repos::PROVIDERS.find { |p| p.accepts_id? scm_id }
        raise UnknownSCMException.new(name) unless provider_clazz

        logger.info "Preparing app #{name} with #{provider_clazz} using #{scm_url}"
        FileUtils.mkdir_p(repo_dir)

        provider = provider_clazz.new(@config)
        return nil unless provider.create_application(name, repo_dir, scm_url, {:name => name}, logger)
      end
      
      app_id
    end
    
    def admit(app_id, commit_id, patch_fn, logger, only_acts = nil)
      repo_dir = File.expand_path(File.join(@data_dir, app_id))
      raise UnknownApplicationException.new(app_id) unless File.exists? repo_dir
      
      provider_clazz = Booth::Repos::PROVIDERS.find { |p| p.accepts_dir? repo_dir }
      raise UnknownSCMException.new(app_id) unless provider_clazz
      
      provider = provider_clazz.new(@config)
      provider.prepare(app_id, repo_dir, commit_id, patch_fn, logger)
      config = provider.config_for(repo_dir)
      
      app_name = config[:name] || app_id
      app = Circus::Application.new(repo_dir, app_name)
      output_path = File.join(File.expand_path(@config.build_dir), app_id)
      return [] unless app.assemble!(output_path, logger, false, only_acts)
      
      store = Circus::ActStoreClient.new(@config.act_store, logger)
      app.upload(output_path, store, only_acts)
      
      # Return the list of generated acts along with the location they were uploaded to
      app.acts.select {|a| only_acts.nil? or only_acts.include? a.name }.map do |act|
        {:name => act.name, :url => "#{@config.act_store}/#{act.name}.act"}
      end
      
      # clown_client = Circus::ClownClient.new(@connection, logger)
      # app.acts.select {|a| only_acts.nil? or only_acts.include? a.name }.each do |act|
      #   # logger.info("Request deploy of #{act.name} to #{config[:target]}")
      #   
      #   # TODO: Make async
      #   # clown_client.deploy(config[:target], act.name, "#{@config.act_store}/#{act.name}.act").result
      # end
      
      # true
    end
    
    def get_ssh_key(logger)
      home = ENV['HOME']
      ssh_private_key = File.join(home, '.ssh', 'id_rsa')
      ssh_public_key = ssh_private_key + ".pub"
      
      unless File.exists? ssh_public_key
        logger.info("No key currently configured. Generating.")
        
        FileUtils.mkdir_p(File.dirname(ssh_private_key))
        res = `ssh-keygen -q -f #{ssh_private_key} -N '' 2>&1`
        
        if $? != 0
          logger.failed("Generation operation failed! Output was: #{res}")
          return ''
        end
      end
      
      File.read(ssh_public_key)
    end
    
    def generate_id(name, scm_url)
      config_digest = Digest::MD5.hexdigest("#{scm_url}")
      
      "#{name}_#{config_digest}"
    end
  end
  
  class UnknownSCMException < StandardError
    def initialize(name)
      super "Unknown provider #{name}"
    end
  end
  
  class UnknownApplicationException < StandardError
    def initialize(name)
      super "Application #{name} not registered"
    end
  end
end