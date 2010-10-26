#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/cli'
require 'bundler'

Bundler.ui = Bundler::UI::Shell.new(Thor::Shell::Basic.new)

# TODO: Make RUBY_FRAMEWORK_VERSION resolvable instead of using 1.8
gem_install_root = "vendor/bundle/ruby/1.8/gems"
spec_install_root = "vendor/bundle/ruby/1.8/specifications"
FileUtils.mkdir_p(gem_install_root)
FileUtils.mkdir_p(spec_install_root)

Bundler.definition.specs.each do |spec|
  install_path = "#{gem_install_root}/#{spec.name}-#{spec.version}"
  
  unless install_path == spec.full_gem_path
    FileUtils.mkdir_p(File.dirname(install_path))
    FileUtils.rm_rf install_path
    FileUtils.cp_r spec.full_gem_path, install_path
  end
  
  File.open(File.join(spec_install_root, "#{spec.name}-#{spec.version}.spec"), 'w') do |sf|
    sf.write(spec.to_ruby)
  end
  in_dir_spec = "#{install_path}/#{spec.name}.gemspec"
  unless File.exists? in_dir_spec
    File.open(in_dir_spec, 'w') do |sf|
      sf.write(spec.to_ruby)
    end
  end
end

File.open('Gemfile', 'w') do |f|
  Bundler.definition.specs.each do |s|
    f << "gem #{s.name.inspect}, #{s.version.to_s.inspect}, :path => '#{gem_install_root}/#{s.name}-#{s.version}'\n"
  end
end
# FileUtils.mkdir_p('.bundle')
# File.open('.bundle/config', 'w') do |f|
#   f.puts '---'
#   f.puts 'BUNDLE_FROZEN: "1"'
#   f.puts 'BUNDLE_DISABLE_SHARED_GEMS: "1"'
#   f.puts 'BUNDLE_PATH: vendor/bundle'
# end