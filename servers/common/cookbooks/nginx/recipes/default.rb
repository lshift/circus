package 'nginx'

service "nginx" do
  action :enable
  supports :restart => true
end
service "nginx" do
  action :start
end