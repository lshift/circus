package "daemontools"
package "daemontools-run"

execute "start svscan" do
  command "start svscan"
  not_if do
    `status svscan`.include? 'process' # If status already includes pid, we don't need to start
  end
end
