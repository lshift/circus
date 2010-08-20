package "ejabberd"

service "ejabberd" do
  action :enable
  supports :restart => true
end

template "/etc/ejabberd/ejabberd.cfg" do
  source "ejabberd.cfg.erb"
  variables(:jabber_domain => node[:jabber_domain])
  notifies :restart, resources(:service => "ejabberd")
end

service "ejabberd" do
  action :start
end

execute do
  command "/etc/init.d/ejabberd start"
end
execute do
  command "sleep 5"
end

execute "add ejabberd admin user" do
  command "ejabberdctl register admin #{node[:jabber_domain]} password"
  not_if do
    users = `ejabberdctl registered-users #{node[:jabber_domain]}`
    users.split("\n").include?('admin')
  end
end
execute "add ejabberd node1 user" do
  command "ejabberdctl register node1 #{node[:jabber_domain]} password"
  not_if do
    users = `ejabberdctl registered-users #{node[:jabber_domain]}`
    users.split("\n").include?('node1')
  end
end
execute "add ejabberd user1 user" do
  command "ejabberdctl register user1 #{node[:jabber_domain]} password"
  not_if do
    users = `ejabberdctl registered-users #{node[:jabber_domain]}`
    users.split("\n").include?('user1')
  end
end