# Ensure we have Nginx
package 'nginx'
service 'nginx' do
  action :enable
  action :start
end

# Point the hostname at the local cache directory
template "/etc/nginx/sites-available/circus-repo.conf" do
  source "repo.circus.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "nginx")
end
link "/etc/nginx/sites-enabled/circus-repo.conf" do
  to "/etc/nginx/sites-available/circus-repo.conf"
end

# Ensure we have the structure for the repository
directory "/var/www/circus-repo" do
  owner 'root'
  group 'root'
  mode 0755
end
directory "/var/www/circus-repo/acts" do
  owner 'root'
  group 'root'
  mode 0755
end
directory "/var/www/circus-repo/debian" do
  owner 'root'
  group 'root'
  mode 0755
end

# Put an index.html in for the root
template "/var/www/circus-repo/index.html" do
  source "index.html.erb"
  owner "root"
  group "root"
  mode 0644
end