directory "/var/cache/chef" do
  action :create
end
directory "/var/cache/chef/packages" do
  action :create
end
remote_file "/var/cache/chef/packages/rubygems-1.3.7.tgz" do
  source "http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz"
end

execute "install rubygems-1.3.7" do
  command "cd /tmp; tar -xzf /var/cache/chef/packages/rubygems-1.3.7.tgz && cd rubygems-1.3.7 && ruby setup.rb"
  not_if do
    gem_version = `gem --version`.strip
    ['1.3.6', '1.3.7'].include? gem_version
  end
  action :run
end

gem_package 'bundler' do
  version '0.9.24'
  action :install
  gem_binary "/usr/bin/gem"
end

gem_package 'rake' do
  action :install
  gem_binary "/usr/bin/gem"
end
gem_package 'rspec' do
  action :install
  gem_binary "/usr/bin/gem"
end

execute "fix .gem ownership" do
  command "chown -R vagrant:vagrant /home/vagrant/.gem"
  action :run
  not_if do
    !::File.exists? '/home/vagrant/.gem'
  end
end
