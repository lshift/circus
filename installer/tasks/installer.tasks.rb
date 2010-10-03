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
    # @scp = Net::SCP.new(@ssh)
  end
end

namespace :install do
  BOOTSTRAP_ACTS = [:ruby_stack, :actstore]
  BASE_ACTS = [:booth_support_stack, :database_stack, :web_stack, :booth, :postgres_tamer, :nginx_tamer]
  OPTIONAL_ACTS = [:erlang_stack, :java_web_stack, :python_stack, :static_web_stack]
  ACTS = BASE_ACTS + OPTIONAL_ACTS
 
  task :ensure_targets do
    @circus_tool ||= "circus"
    @act_arch ||= ENV['ACT_ARCH'] || determine_arch
    @act_root ||= ENV['ACT_ROOT'] || 'http://repo.deployacircus.com/acts/current'
    @bootstrap_root ||= @act_root
    @circus_deb_cfg ||= "deb http://repo.deployacircus.com/debian highwire main"
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

  # Applies the current architecture to an act name, if required
  def act_name_with_arch(name)
    if name.to_s.end_with? 'stack' then name else "#{name}-#{@act_arch}" end
  end
  
  desc "Installs the Clown onto the deployment target"
  task :clown => [:ensure_targets] do
    @ssh.execute do |ssh|
      log_remote_cmd(ssh, "sudo apt-get remove clown --purge -y --force-yes")
      log_remote_cmd(ssh, "sudo sh -c 'echo \"#{@circus_deb_cfg}\" >/etc/apt/sources.list.d/clown-local.list'")
      log_remote_cmd(ssh, "sudo apt-get update")
      log_remote_cmd(ssh, "sudo apt-get install clown -y --force-yes")
      log_remote_cmd(ssh, "sudo start svscan")
    end
  end
  
  BOOTSTRAP_ACTS.each do |name|
    task name => [:ensure_targets] do
      act_fn = act_name_with_arch(name)
      sh "#{@circus_tool} deploy #{@deploy_target} #{name} #{@bootstrap_root}/#{act_fn}.act"
    end
  end
  task :bootstrap => BOOTSTRAP_ACTS
  
  ACTS.each do |name|
    task name => [:ensure_targets] do
      act_fn = act_name_with_arch(name)
      sh "#{@circus_tool} deploy #{@deploy_target} #{name} #{@act_root}/#{act_fn}.act"
    end
  end
  task :base_acts => BASE_ACTS
  task :optional_acts => OPTIONAL_ACTS
  
  task :acts => [:bootstrap, :base_acts, :optional_acts]
  task :all => [:clown, :acts]
end

def log_remote_cmd(ssh, cmd)
  ssh.exec!(cmd) do |channel, stream, data|
    STDOUT << data if stream == :stdout
    STDERR << data if stream == :stderr
  end
end