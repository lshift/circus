require 'blather/client/dsl'
require 'circus/agents/params'
require 'circus/agents/logger'
require 'circus/agents/connection'

module Circus
  module Agents
    class Agent
      include Blather::DSL
    
      class <<self
        def commands
          @commands ||= []
        end
      
        def command(name, &body)
          commands << name
        
          define_method("command_#{name}", &body)
        end
      end
    
      def initialize(connection = nil)
        @client = (connection || Connection.new)
      
        # Approve all subscription requests
        subscription :request? do |s|
          write_to_stream s.approve!
        end
      
        # Add a handler for each chat command
        self.class.commands.each do |name|
          message :chat?, :body => /^#{name}( .*)?$/ do |m|
            # begin
              params = CommandParams.new(m.body[(name.length + 1)..-1])
              logger = XMPPLogger.new(m.from, m.thread || m.id, lambda { |msg| write_to_stream(msg) })
          
              send("command_#{name}", params, logger)
            # rescue
              # puts $!, $@
            # end
          end
        end
      
        disconnected do
          puts "Disconnected"
        end
      end
    
      def configure!(config)
        client.configure!(config)
      end
    
      def run
        client.run
      end
    end
  end
end