require 'ostruct'
require 'thor'
#require 'circus/agents/connection'
require 'circus/clown_client'
require 'circus/booth_client'
require 'circus/booth_tool'
require 'circus/version'

module Circus
  class CLI < Thor
    LOGGER = StdoutLogger.new
    
    #
    # Global Options
    #
    
    class_option :source, :default => '.', :desc => 'Source directory containing the application'
    
    
    #
    # Actions
    #
    
    desc "go", "Run the current application in place for development"
    def go
      load!
      @app.go!(LOGGER)
    end
    
    desc "pause ACT_NAME", "Temporarily halts an act that is running in development (via go)"
    def pause(act_name)
      load!
      @app.pause(LOGGER, act_name)
    end
    
    desc "resume ACT_NAME", "Resumes a paused act that is running in development (via go)"
    def resume(act_name)
      load!
      @app.resume(LOGGER, act_name)
    end
    
    desc "assemble", "Assemble the application's acts for deployment"
    method_option :output, :default => '.circus/acts/', :desc => 'Destination directory for generated acts'
    method_option :actstore, :desc => 'URL of the act store to upload the built acts to'
    method_option :dev, :type => :boolean, :default => false, :desc => 'Make assembly for local dev use only'
    def assemble
      load!
      
      output_path = File.expand_path(options[:output])
      dev = options[:dev]

      @app.assemble!(output_path, LOGGER, dev)
      if options[:actstore]
        store = ActStoreClient.new(options[:actstore], LOGGER)
        @app.upload(output_path, store)
      end
    end

    desc "upload FILENAME", "Uploads the given set of act files to act store"
    method_option :actstore, :required => true, :desc => 'URL of the act store to upload builds to'
    def upload(fn)
      store = ActStoreClient.new(options[:actstore], LOGGER)
      store.upload_act(fn)
    end
    
    desc "get-booth-key BOOTH", "Retrieves the public key that a booth will use when connecting to SSH resources"
    def get_booth_key(booth)
      connection = ConnectionBuilder.new(options).build(booth)
      
      client = BoothClient.new(connection, LOGGER)
      key = client.get_ssh_key(booth).result
      puts "SSH key for: #{booth}"
      puts "  #{key}"
    end
    
    desc "connect NAME BOOTH", "Associates the local application with the provided booth to allow for deployment"
    method_option :deploy_target, :desc => 'The target for application deployment. Uses same host as booth if not specified.'
    method_option :app_name, :desc => 'The name of the application being configured. Defaults to application directory name.'
    method_option :repo_type, :desc => 'The type of the repository being deployed. Defaults to type of current working directory.'
    method_option :repo_url, :desc => 'The URL of the repository being deployed. Defaults to the primary url of current working directory.'
    
    # method_option :jid, :required => true, :desc => 'The deployer jid to connect as'
    # method_option :host, :required => true, :desc => 'The XMPP host to connect to'
    # method_option :port, :type => :numeric, :default => 5222, :desc => 'The XMPP port to connect to'
    # method_option :password, :required => true, :desc => 'The XMPP user password'
    def connect(name, booth)
      config = LocalConfig.new
      tool = BoothTool.new(LOGGER, config)
      tool.connect(name, booth, options)
      config.save!
    end
    
    desc "admit [NAME] [ACT1 ACT2]", "Admits and deploys the application with the given booth reference"
    method_option :uncommitted, :desc => 'Indicates that the current uncommitted changes should be sent to the booth and included in the app'
    def admit(name = nil, *apps)
      tool = BoothTool.new(LOGGER, LocalConfig.new)
      tool.admit(name, apps, options)
    end

    desc "exec TARGET [ACT] [CMD]", "Executes the given command in the deployed context of the given act"
    # method_option :jid, :required => true, :desc => 'The deployer jid to connect as'
    # method_option :host, :required => true, :desc => 'The XMPP host to connect to'
    # method_option :port, :type => :numeric, :default => 5222, :desc => 'The XMPP port to connect to'
    # method_option :password, :required => true, :desc => 'The XMPP user password'
    def exec(target, act_name, *cmd_parts)
      cmd = cmd_parts.join(' ')
      
      connection = ConnectionBuilder.new(options).build(target)
      client = ClownClient.new(connection, LOGGER)
      client.exec(target, act_name, cmd).result
    end
    
    desc "deploy TARGET NAME ACT", "Deploy the named object using the given act onto the given target server"
    method_option :config, :desc => 'URL of configuration object to use at deployment'
    # method_option :actstore, :required => true, :desc => 'The store to retrieve the act from'
    # method_option :jid, :required => true, :desc => 'The deployer jid to connect as'
    # method_option :host, :required => true, :desc => 'The XMPP host to connect to'
    # method_option :port, :type => :numeric, :default => 5222, :desc => 'The XMPP port to connect to'
    # method_option :password, :required => true, :desc => 'The XMPP user password'
    def deploy(target, name, act)
      connection = ConnectionBuilder.new(options).build(target)
      
      client = ClownClient.new(connection, LOGGER)
      client.deploy(target, name, act, options[:config]).result
    end
    
    desc "undeploy TARGET NAME", "Undeploys the named act from the given target server"
    # method_option :jid, :required => true, :desc => 'The deployer jid to connect as'
    # method_option :host, :required => true, :desc => 'The XMPP host to connect to'
    # method_option :port, :type => :numeric, :default => 5222, :desc => 'The XMPP port to connect to'
    # method_option :password, :required => true, :desc => 'The XMPP user password'
    def undeploy(target, name)
      connection = ConnectionBuilder.new(options).build(target)
      
      client = ClownClient.new(connection, LOGGER)
      client.undeploy(target, name).result
    end
    
    desc "configure TARGET NAME CONFIG", "(Re)configures the given act on the given target using the provided config details"
    def configure(target, name, config)
      connection = ConnectionBuilder.new(options).build(target)
      
      client = ClownClient.new(connection, LOGGER)
      client.configure(target, name, config).result
    end
    
    desc "alias NAME TARGET", "Adds an alias so that NAME can be used when target TARGET is desired"
    def alias(name, target)
      local_config = LocalConfig.new
      local_config.aliases[name] = target
      local_config.save!
    end
    
    private
      def load!
        @app = Circus::Application.new(File.expand_path(options[:source]))
      end
  end
end
