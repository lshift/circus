require 'rubygems'
require 'rack'
require 'webrick'

class DevFileserver
  THREADS = []
  SERVERS = []

  def self.start
    trap("INT") { threadDestroyAll() }

    THREADS << Thread.new do
      DevFileserver.new.run
    end
  end

  def self.threadDestroyAll
    SERVERS.each { |s| s.shutdown }
    Thread.main.kill
  end

  def run
    trap("INT") { DevFileserver.threadDestroyAll() }
    file_adapter = Rack::File.new(File.expand_path('../../packages', __FILE__))
    server = ::WEBrick::HTTPServer.new(:Port => 7654)
    server.mount "/", Rack::Handler::WEBrick, file_adapter
    SERVERS << server
    server.start
  end
end
