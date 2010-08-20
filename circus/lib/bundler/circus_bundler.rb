#!/usr/bin/env ruby

# Circus specific entry-point for bundler that handles the packaging of gems for an application.
require 'rubygems'
require 'bundler'
require 'bundler/cli'
require File.expand_path('../patches', __FILE__)
require File.expand_path('../circus_util', __FILE__)

class LoggingShell
  def say(msg)
    puts msg
  end
end

# Run the bundler install
dir = File.expand_path('.')
ENV['BUNDLE_GEMFILE'] = File.join(dir, 'Gemfile')
Bundler.settings[:path] = 'vendor'
Bundler.ui = Bundler::UI::Shell.new(LoggingShell.new)
Gem::DefaultUserInteraction.ui = Bundler::UI::RGProxy.new(Bundler.ui)
Bundler::Installer.install(Bundler.root, Bundler.definition, {})

Bundler::CircusUtil.fix_external_paths(dir)