execute "apt update" do
  command 'apt-get update'
end

template "/etc/apt/sources.list.d/circus.list" do
  source "circus.list.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :run, resources(:execute => "apt update"), :immediately
end
