# Environment for specs
begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
  Bundler.require(:default, :test)
end

TMP_DIR = File.expand_path('../../tmp', __FILE__)