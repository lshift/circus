module Circus
  module Agents
    class DBusLogger
      def initialize(adapter, action_id)
        @adapter = adapter
        @action_id = action_id
      end
  
      def info(content)
        write(content)
      end

      def error(content)
        write("ERROR: #{content}")
      end

      def failed(msg)
        write("failed #{msg}")
      end

      def complete(res = nil)
        if res
          write("ok #{Encoding.encode(res)}") 
        else
          write('ok')
        end
      end
  
      def write(msg)
        @adapter.LogEntry(@action_id, msg)
      end
    end
  end
end