require 'dbus'
require 'circus/agents/dbus_logger'
require 'json'

module Postgres
  class DBusAdapter < DBus::Object
    attr_reader :exported
    
    def initialize(worker)
      super('/com/deployacircus/Postgres')
      @worker = worker
      
      @bus = DBus::SystemBus.instance
      @s = @bus.request_service('com.deployacircus.Postgres')
      @exported = @s.export(self)
    end
    
    dbus_interface 'com.deployacircus.ResourceAllocator' do
      dbus_signal :LogEntry, 'id:s, entry:s'
      
      dbus_method :allocate, "in id:s, in spec:s, out db_id:s" do |id, spec|
        logger = Circus::Agents::DBusLogger.new(self, id)
        
        details = JSON.parse(spec)
        logger.info("Allocating database: #{details['name']}")
        
        [@worker.create_database(details['name'], details['user'], details['password'], logger)]
      end
    end
    
    def run
      l = DBus::Main.new
      l << @bus
      l.run
    end
  end
end