#require File.expand_path('../clown/xmpp', __FILE__)
require File.expand_path('../clown/dbus_adapter', __FILE__)
require File.expand_path('../clown/worker', __FILE__)
require File.expand_path('../clown/runner', __FILE__)
require File.expand_path('../clown/config', __FILE__)
require File.expand_path('../clown/resources', __FILE__)

module Clown
  def self.VERSION
    '0.0.1'
  end
end


runner = Clown::Runner.new(ARGV)
runner.run!