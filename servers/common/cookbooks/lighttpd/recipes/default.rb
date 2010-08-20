package 'lighttpd'
execute "disable lighttpd startup" do
  command "update-rc.d -f lighttpd remove"
end
