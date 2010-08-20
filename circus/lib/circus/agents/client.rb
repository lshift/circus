require 'circus/agents/encoding'
require 'monitor'

module Circus
  module Agents
    # Client for XMPP based agents.
    class Client
      def initialize(connection)
        @connection = connection
      end
    
      def call(to, name, params = {}, &block)
        body = if params.length > 0
            "#{name} #{Encoding.encode(params)}"
          else
            name
          end
        msg = Blather::Stanza::Message.new to, body
        msg.id = Blather::Stanza.next_id
        msg.thread = msg.id
        
        promise = Promise.new
        last = nil
        @connection.register_thread_handler(msg.thread) do |m|
          block.call(m)

          begin
            if Conversation.ended? m
              result = nil
              if last and last.body and last.body.start_with? 'ok '
                result = Encoding.decode(last.body[('ok '.length)..-1])
              end
            
              promise.completed!(result)
            else
              last = m
            end
          rescue
            puts $!, $@
          end
        end
        @connection.write(msg)
      
        promise
      end
    end
  
    # A promise provides a reference to an expected future result. Client calls
    # return immediately upon message dispatch - in order to retrieve the final
    # result, the promise can be inspected.
    class Promise
      def initialize
        @monitor = Monitor.new
        @cond = @monitor.new_cond
        @completed = false
        @result = nil
      end
      
      def completed!(result)
        @monitor.synchronize do
          @completed = true
          @result = result
          @cond.signal
        end
      end
      
      def result
        @monitor.synchronize do
          return @result if @completed
          
          @cond.wait
          @result
        end
      end
    end
  end
end