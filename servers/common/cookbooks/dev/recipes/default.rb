template '/etc/apt/sources.list.d/local.list' do
  source 'local.list'
  mode '0644'
end

execute "apt update" do
  command 'apt-get update'
end
