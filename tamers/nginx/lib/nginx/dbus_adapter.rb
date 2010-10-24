require 'dbus'
require 'circus/agents/dbus_logger'
require 'json'

module Nginx
  class DBusAdapter < DBus::Object
    attr_reader :exported
    
    def initialize(worker)
      super('/com/deployacircus/Nginx')
      @worker = worker
      
      @bus = DBus::SystemBus.instance
      @s = @bus.request_service('com.deployacircus.Nginx')
      @exported = @s.export(self)
    end
    
    dbus_interface 'com.deployacircus.ResourceAllocator' do
      dbus_signal :LogEntry, 'id:s, entry:s'
      
      dbus_method :allocate, "in id:s, in spec:s, out db_id:s" do |id, spec|
        logger = Circus::Agents::DBusLogger.new(self, id)
        
        details = JSON.parse(spec)
        logger.info("Allocating host: #{details['hostname']} to #{details['target']}")
        
        [@worker.forward_hostname(details['hostname'], details['target'], details['app_root'], logger)]
      end
    end
    
    def run
      l = DBus::Main.new
      l << @bus
      l.run
    end
  end
end