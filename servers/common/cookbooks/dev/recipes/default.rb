template '/etc/apt/sources.list.d/local.list' do
  source 'local.list'
end
file '/etc/apt/sources.list.d/local.list' do
  mode '644'
end

execute "apt update" do
  command 'apt-get update'
end
