# Collection of common tasks for executing on remote nodes

namespace :remote do
  desc "Ensures that a TARGET environment variable has been set"
  task :ensure_target do
    @target = ENV['TARGET']
    unless @target
      puts "Please specify a TARGET host, such as ssh://myserver.com"
      fail
    end
    @uri = URI.parse(@target)
  
    @current_user = ENV['USER']
    @deploy_target = "ssh://#{@current_user}@#{@uri.host}"
  end

  task :ensure_root_ssh => [:ensure_target] do
    root_pw = ask("Enter root password for #{@uri.host}: ") { |q| q.echo = false }

    opts = {:port => @uri.port || 22, :password => root_pw}
    @ssh = Net::SSH.start(@uri.host, 'root', opts)
    @scp = Net::SCP.new(@ssh)
  end
end

def log_remote_cmd(ssh, cmd)
  ssh.exec!(cmd) do |channel, stream, data|
    STDOUT << data if stream == :stdout
    STDERR << data if stream == :stderr
  end
end
