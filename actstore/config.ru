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

require 'ostruct'
require 'fileutils'
require 'actstore/actstore'

CONFIG = OpenStruct.new({
  :data_dir => ENV['DATA_DIR'] || 'data'
})

FileUtils.mkdir_p(CONFIG.data_dir)

set :run, false
set :environment, :production
run Sinatra::Application