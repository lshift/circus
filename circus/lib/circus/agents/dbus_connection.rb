require 'dbus'
require 'uuid'

module Circus
  module Agents
    class DBusConnection
      def initialize(bus = nil)
        @bus = bus || DBus::SystemBus.instance
      end
      
      def configure_bg!(options = {})
        Thread.new do
          l = DBus::Main.new
          l << @bus
          l.run
        end 
      end
      
      def call(target, object, iface, method, args, logger)
        action_id = UUID.generate
        
        @service = @bus.service("com.deployacircus.#{object}")
        obj = @service.object("/com/deployacircus/#{object}")
        obj.introspect
        obj_iface = obj["com.deployacircus.#{iface}"]
        dbus_method = obj_iface.methods[method]
        raise ArgumentError.new("Method #{method} on #{object} not found") unless dbus_method
        
        msg = DBus::Message.new(DBus::Message::METHOD_CALL)
        msg.path = obj.path
        msg.interface = obj_iface.name
        msg.destination = obj.destination
        msg.member = dbus_method.name
        msg.sender = @bus.unique_name
        dbus_method.params.each do |p|
          if p.name == 'id'
            msg.add_param p.type, action_id
          else
            msg.add_param(p.type, args[p.name])
          end
        end
        promise = DBusPromise.new(@bus)
        @bus.on_return(msg) do |rmsg|
          promise.completed!(rmsg)
        end
        obj_iface.on_signal(@bus, 'LogEntry') do |log_action_id, msg|
          logger.info(msg) if action_id == log_action_id
        end
        @bus.send(msg.marshall)
        
        promise
      end
      
      def send_file(fn)
        # Normal DBus connections can see the file locally just fine, so we don't need to
        # do anything with it.
        fn
      end
    end
    
    class DBusPromise
      def initialize(bus)
        @bus = bus
        @l = DBus::Main.new
        @l << @bus
        @result = nil
      end
      
      def result
        @l.run
        
        if @result.is_a? DBus::Error
          raise @result
        else
          @result.params[0]
        end
      end
      
      def completed!(result)
        @result = result
        @l.quit
      end
    end
  end
end