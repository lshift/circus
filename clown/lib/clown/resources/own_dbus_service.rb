require 'fileutils'

module Clown
  module Resources
    # Provides the ability for the user executing an act to take ownership of
    # a DBus service
    class OwnDBusService
      def self.configurable_props
        ['own-dbus-service']
      end
      
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['own-dbus-service']
          resource_data['own-dbus-service'].each do |service_name|
            service_file = <<-EOT
            <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
             "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
            <busconfig>
              <!-- Allow #{env[:user]} user to own the service -->
              <policy user="#{env[:user]}">
                <allow own="#{service_name}"/>
                <allow send_destination="#{service_name}" />
              </policy>

              <!-- Allow root and admin users to talk to the app -->
              <policy user="root">
                <allow send_destination="#{service_name}" />
              </policy>
              <policy group="admin">
                <allow send_destination="#{service_name}" />
              </policy>
            </busconfig>
            EOT
            
            File.open(File.join(@config.dbus_system_path, "#{service_name}.conf"), 'w') do |f|
              f.write(service_file)
            end

            res = `reload dbus`
            if $? != 0
              @logger.error("Failed to request dbus configuration reload: #{res}")
            end
          end
        end
      end
    end

    RESOURCES << OwnDBusService
  end
end
