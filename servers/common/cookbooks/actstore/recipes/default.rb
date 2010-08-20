apache_module 'dav' do
  action :enable
end
apache_module 'dav_fs' do
  action :enable
end

directory "/var/www/acts" do
  action :create
  mode 0755
  owner "www-data"
  group "www-data"
end
file "#{node[:apache][:dir]}/sites-enabled/000-default" do
  action :delete
  notifies :restart, resources(:service => "apache2")
end

template "#{node[:apache][:dir]}/sites-available/001-actserver" do
  source 'actserver_vhost.conf.erb'
  notifies :restart, resources(:service => "apache2")
end
apache_site '001-actserver' do
  action :enable
end