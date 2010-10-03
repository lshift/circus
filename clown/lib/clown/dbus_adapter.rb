require 'dbus'
require 'circus/agents/dbus_logger'

module Clown
  class DBusAdapter < DBus::Object
    attr_reader :exported
    
    def initialize(worker)
      super('/com/deployacircus/Clown')
      @worker = worker
      
      @bus = DBus::SystemBus.instance
      @s = @bus.request_service('com.deployacircus.Clown')
      @exported = @s.export(self)
    end
    
    dbus_interface 'com.deployacircus.Clown' do
      dbus_signal :LogEntry, 'id:s, entry:s'
      
      dbus_method :deploy, "in id:s, in name:s, in url:s, in config_url:s" do |id, name, url, config_url|
        logger = Circus::Agents::DBusLogger.new(self, id)
        execute_safely(logger) do
          @worker.deploy(name, url, config_url, logger)
        end
      end
      
      dbus_method :undeploy, "in id:s, in name:s" do |id, name|
        logger = Circus::Agents::DBusLogger.new(self, id)
        execute_safely(logger) do
          @worker.undeploy(name, logger)
        end
      end
      
      dbus_method :reset, "in id:s, in name:s" do |id, name|
        logger = Circus::Agents::DBusLogger.new(self, id)
        execute_safely(logger) do
          @worker.reset(name, logger)
        end
      end
            
      dbus_method :configure, "in id:s, in name:s, in config_url:s" do |id, name, config_url|
        logger = Circus::Agents::DBusLogger.new(self, id)
        execute_safely(logger) do
          @worker.configure(name, config_url, logger)
        end
      end
      
      dbus_method :exec, "in id:s, in name:s, in command:s" do |id, name, cmd|
        logger = Circus::Agents::DBusLogger.new(self, id)
        execute_safely(logger) do
          @worker.exec(name, cmd, logger)
        end
      end
    end
    
    def execute_safely(logger)
      begin
        yield
      rescue
        logger.failed("#{$!}")
      end
    end
    
    def run
      l = DBus::Main.new
      l << @bus
      l.run
    end
  end
end