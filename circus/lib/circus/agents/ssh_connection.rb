require 'dbus'
require 'uuid'
require 'net/ssh'
require 'net/scp'
require 'uri'
require 'circus/agents/dbus_connection'

module Circus
  module Agents
    class SSHConnection < DBusConnection
      def initialize(target)
        addr = "/tmp/circus-#{UUID.generate}"
        @uri = URI.parse(target)
        @ssh = open_ssh
        # Determine our remote uid so we can use that in authentication requests
        remote_uid = @ssh.exec!('id -u').strip

        @acceptor = Socket.new(Socket::Constants::PF_UNIX, Socket::Constants::SOCK_STREAM, 0)
        @acceptor.bind(Socket.pack_sockaddr_un(addr))
        @acceptor.listen(5)
        
        Thread.new do
          begin
            socket, info = @acceptor.accept
            @ssh.open_channel do |channel|
              channel.exec('nc -U /var/run/dbus/system_bus_socket') do |ch, success|
                abort "Couldn't open DBus connection" unless success

                socket.extend(Net::SSH::BufferedIo)
                @ssh.listen_to(socket)

                ch.on_process do
                  if socket.available > 0
                    ch.send_data(socket.read_available)
                  end
                end

                ch.on_data do |ch, data|
                  socket.write(data)
                end

                ch.on_close do
                  @ssh.stop_listening_to(socket)
                  socket.close
                end
              end
            end
            @ssh.loop
          rescue
            puts "SSH connector thread died:"
            puts $!, $@
          end
        end
        
        bus = RemoteDBusConnection.new("unix:path=#{addr}", remote_uid)
        
        super(bus)
      end
      
      def send_file(fn)
        # Perform an SCP upload of the file into the /tmp of the target
        target_fn = File.join('/tmp', File.basename(fn))
        
        scp_ssh = open_ssh
        scp = Net::SCP.new(scp_ssh)
        scp.upload!(fn, target_fn)
        scp_ssh.exec!("chmod ugo+r #{target_fn}")
        scp_ssh.close
        target_fn
      end
      
      private
        def open_ssh
          Net::SSH.start(@uri.host, @uri.user || ENV['USER'], :port => @uri.port || 22)
        end
    end
    
    class RemoteDBusConnection < DBus::Connection
      def initialize(path, remote_uid)
        super(path)
        
        @remote_uid = remote_uid
        
        connect
        send_hello
      end
      
      def init_connection
        @client = DBus::Client.new(@socket)
        @client.auth_list = [RemoteExternal.new(@remote_uid)]
        @client.authenticate
      end
    end
    
    class RemoteExternal
      def initialize(uid)
        @uid = uid
      end
      
      # Make this look like a class that can be instantiated
      def new
        self
      end
      
      def name
        'EXTERNAL'
      end
      
      def authenticate
        @uid.to_s.split(//).collect { |a| "%x" % a[0].ord }.join
      end
    end
  end
end

module DBus
  class Client
    attr_accessor :auth_list
  end
end