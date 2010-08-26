require_recipe 'daemontools'

package 'clown' do
  options "--force-yes"
end
execute 'reload dbus' do
  command 'reload dbus'
end
