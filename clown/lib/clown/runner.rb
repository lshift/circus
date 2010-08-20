require 'optparse'
require 'yaml'

module Clown
  class Runner
    def initialize(argv)
      @argv = argv
      @options = {
        :config_file => File.expand_path(File.join(__FILE__, "../../../config/clown.config"))
      }
      
      parse!
    end
    
    # Parse the options.
    def parse!
      parser.parse! @argv
    end
        
    def parser
       @parser ||= OptionParser.new do |opts|
         opts.banner = "Usage: clown [options]"
         
         opts.separator ""
         opts.separator "Clown options:"

         opts.on("-c", "--config FILE", "uses FILE to configure connectivity and deployment",
                                         "(default: #{@options[:config_file]})")         { |f| @options[:config_file] = File.expand_path(f) }
         
         opts.separator "Common options:"

         opts.on_tail("-h", "--help", "Show this message")                               { puts opts; exit }
         opts.on_tail('-v', '--version', "Show version")                                 { puts Clown::VERSION; exit }
       end
    end
    
    def run!
      # EM.error_handler{ |e|
      #  puts "Error raised during event loop: #{e.message}"
      # }
      
      # Load the configuration file
      config = Clown::Config.new(@options[:config_file])
      # connection = Circus::Agents::Connection.new
      # connection.configure! config

      worker = Clown::Worker.new(config)
      # clown_xmpp = Clown::XMPP.new(connection, worker)
      clown_dbus = Clown::DBusAdapter.new(worker)
      clown_dbus.run
      # EM.run {
      #   clown_xmpp.run
      # }
    end
  end
end