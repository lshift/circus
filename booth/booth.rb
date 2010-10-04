require "rubygems"
require "bundler"
Bundler.setup

$: << File.expand_path('../lib', __FILE__)

require 'booth/config'
# require 'booth/xmpp'
require 'booth/worker'
require 'booth/dbus_adapter'

require 'booth/repos/base'
require 'booth/repos/git'
require 'booth/repos/mercurial'

require 'etc'

# require 'circus/agents/connection'

# EM.error_handler{ |e|
#  puts "Error raised during event loop: #{e.message}\n#{e.backtrace.join("\n")}"
# }

config = Booth::Config.new(File.expand_path('../config/booth.config', __FILE__))
# connection = Circus::Agents::Connection.new
# connection.configure! config

# Set our HOME to our current user's profile dir to make various build tools work
etc_pw_details = Etc.getpwnam(`id -un`.strip)
# ENV['HOME'] = etc_pw_details.dir || config.data_dir

Bundler.with_clean_env do
  booth_dbus = Booth::DBusAdapter.new(Booth::Worker.new(nil, config))
  booth_dbus.run
end