require 'blather/client/client'
require 'circus/agents/conversation'
require 'monitor'

module Circus
  module Agents
    class Connection < Blather::Client
      attr_reader :thread_handlers
    
      def initialize
        super
      
        @ready_mon = Monitor.new
        @ready_cond = @ready_mon.new_cond
        @thread_handlers = {}
        register_handler :message do |m|
          process_chat_thread(m)
        end
        register_handler :disconnected do
          puts "Disconnected!"
        end
        register_handler :ready do
          @ready_mon.synchronize {
            @ready_cond.signal
          }
        end
      end
    
      def configure!(config)
        args = [config.jid, config.password]
        if config.host
          args << config.host
          args << config.port if config.port
        end 
      
        setup *args
      end
      
      def configure_bg!(config)
        configure!(config)
        
        Thread.new {
          EM.run { 
            begin
              run
            rescue
              puts $!, $@
            end
          }
        }
        @ready_mon.synchronize {
          @ready_cond.wait(2)
        }
      end
    
      def register_thread_handler(thread_id, &block)
        thread_handlers[thread_id] = block
      end
    
      def remove_thread_handler(thread_id)
        thread_handlers.delete(thread_id)
      end
    
      private
        def process_chat_thread(m)
          return false unless m.thread and thread_handlers[m.thread]
        
          handler = thread_handlers[m.thread]
          remove_thread_handler(m.thread) if Conversation.ended? m
        
          handler.call(m)
          true
        end
    end
  end
end