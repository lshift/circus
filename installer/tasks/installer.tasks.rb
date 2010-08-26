namespace :install do
  ACTS = {:actstore => 'actstore', :booth => 'booth', :postgres_tamer => 'postgres', :nginx_tamer => 'nginx'}
 
  task :use_source do
    require 'dev_fileserver'
    
    DevFileserver.start
    
    ENV['ALT_CIRCUS_DEB_REPO'] = 'http://192.168.11.1:7654/debian'
    @act_root='http://192.168.11.1:7654/acts'
  end
 
  task :ensure_targets do
    @act_arch ||= ENV['ACT_ARCH'] || determine_arch
    @act_root ||= ENV['ACT_ROOT'] || 'http://repo.deployacircus.com/acts/current'
    fail "@deploy_target must have been set before using these .tasks" unless @deploy_target
  end

  def determine_arch
    opts = {:port => @uri.port || 22}
    @ssh = Net::SSH.start(@uri.host, @current_user, opts)

    case @ssh.exec!("uname -m").strip
      when "x86_64" then "x64"
      else "i386"
    end
  end
  
  task :acts => [:ensure_targets] do
    ACTS.each do |task_name, act_name|
      sh "../circus/bin/circus deploy #{@deploy_target} #{act_name} #{@act_root}/#{act_name}-#{@act_arch}.act"
    end
  end
end
