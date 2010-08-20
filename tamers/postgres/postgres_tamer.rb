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

require 'postgres/dbus_adapter'
require 'postgres/worker'

require 'ostruct'

# EM.error_handler{ |e|
#  puts "Error raised during event loop: #{e.message}"
# }

config = OpenStruct.new({
  # :jid      => 'postgres@localhost',
  # :password => 'password',
  # :host     => 'localhost',
#  :port     => 5223,
})

# connection = Circus::Agents::Connection.new
# connection.configure! config
pg_dbus = Postgres::DBusAdapter.new(Postgres::Worker.new(config))
pg_dbus.run


# EM.run {
#   pg.run
# }
