require 'circus/agents/encoding'
require 'circus/agents/conversation'

module Circus
  module Agents
    class XMPPLogger
      def initialize(to, thread, writer)
        @to = to
        @thread = thread || "thread#{Blather::Stanza.next_id}"
        @writer = writer
      end
    
      def info(content)
        write("#{content}")
      end
    
    
      def error(content)
        write("ERROR: #{content}")
      end

      def failed(msg)
        write("failed #{msg}")
        gone
      end
    
      def complete(res = nil)
        if res
          write("ok #{Encoding.encode(res)}") 
        else
          write('ok')
        end
        gone
      end
    
      private
        def write(content)
          msg = Blather::Stanza::Message.new @to, content
          msg.thread = @thread
          @writer.call(msg)
        end
      
        def gone
          msg = Blather::Stanza::Message.new @to, nil
          msg.thread = @thread
      
          Conversation.end(msg)
          @writer.call(msg)
        end
    end
  end
end