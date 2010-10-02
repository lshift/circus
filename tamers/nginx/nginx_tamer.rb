begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end
$: << File.expand_path('../lib', __FILE__)

require 'nginx/dbus_adapter'
require 'nginx/worker'

require 'ostruct'

config = OpenStruct.new({
  :config_dir => '/etc/nginx/sites-enabled'
  
  # :jid      => 'postgres@localhost',
  # :password => 'password',
  # :host     => 'localhost',
#  :port     => 5223,
})

ng_dbus = Nginx::DBusAdapter.new(Nginx::Worker.new(config))
ng_dbus.run