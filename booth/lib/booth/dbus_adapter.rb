require 'dbus'
require 'circus/agents/dbus_logger'

module Booth
  class DBusAdapter < DBus::Object
    attr_reader :exported
    
    def initialize(worker)
      super('/com/deployacircus/Booth')
      @worker = worker
      
      @bus = DBus::SystemBus.instance
      @s = @bus.request_service('com.deployacircus.Booth')
      @exported = @s.export(self)
    end
    
    dbus_interface 'com.deployacircus.Booth' do
      dbus_signal :LogEntry, 'id:s, entry:s'
      
      dbus_method :create, "in id:s, in name:s, in scm:s, in scm_url:s, out app_id:s" do |id, name, scm, scm_url|
        logger = Circus::Agents::DBusLogger.new(self, id)
        app_id = @worker.create_application(name, scm, scm_url, logger)
        if app_id
          [app_id]
        else
          logger.failed('application creation failed')
          ['']
        end
      end
      
      dbus_method :admit, "in id:s, in app_id:s, in commit_id:s, in patch_fn:s, in acts:s, out built_acts:s" do |id, app_id, commit_id, patch_fn, acts|
        act_list = acts.split(',')
        act_list = nil unless act_list.length > 0
        
        logger = Circus::Agents::DBusLogger.new(self, id)
        result = {}
        @worker.admit(app_id, commit_id, patch_fn, logger, act_list).each do |res|
          result[res[:name]] = res[:url]
        end
        [Circus::Agents::Encoding.encode(result)]
      end
      
      dbus_method :get_ssh_key, "in id:s, out ssh_key:s" do |id|
        logger = Circus::Agents::DBusLogger.new(self, id)
        [@worker.get_ssh_key(logger)]
      end
    end
    
    def run
      l = DBus::Main.new
      l << @bus
      l.run
    end
  end
end