require 'circus/agents/dbus_connection'
require 'circus/agents/ssh_connection'

module Circus
  class ConnectionBuilder
    def initialize(options)
      @options = options
      @local_config = LocalConfig.new
    end
    
    def build(target)
      if not target.include? ':'
        if @local_config.aliases.include? target
          build(@local_config.aliases[target])
        else
          raise ArgumentError.new("Invalid target #{target} - looks like an alias, but none configured to match")
        end
      elsif target.start_with? 'local:'
        # Local connection
        client = Agents::DBusConnection.new
        # client.configure_bg!
        client
      elsif target.start_with? 'ssh://'
        # SSH connection
        client = Agents::SSHConnection.new(target)
        client
      elsif
        raise ArgumentError.new("Ivalid target #{target} - unknown protocol")
      end
    end
  end
end