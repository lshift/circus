# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'circus/version'

Gem::Specification.new do |s|
  s.name = "circus-deployment"
  s.version = Circus::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Paul Jones"]
  s.email = ["pauljones23@gmail.com"]
  s.homepage = "http://github.com/lshift/circus"
  s.summary = "Deploying the circus that is your application"
  s.description = "Circus provides the ability to deploy multi-component applications easily"

  s.required_rubygems_version = ">= 1.3.2"

  s.add_development_dependency "rspec"

  s.files = Dir.glob("{bin,lib,vendor}/**/*") + %w(LICENSE README.md)
  s.executables = ['circus']
  s.require_paths = ['lib', 'vendor/ruby-dbus/lib']
  
  s.add_dependency('thor', ['>= 0.13.4'])
  s.add_dependency('uuid', ['2.0.1'])
  s.add_dependency('net-ssh', ['2.0.22'])
  s.add_dependency('net-scp', ['1.0.2'])
  s.add_dependency('json_pure', ['1.4.6'])
end
