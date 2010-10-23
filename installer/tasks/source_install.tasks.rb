namespace :install do
  # Configures the build to use source. Hardwires a bunch of properties to local variants. By default, will upload acts
  # to the remote machine's actstore. If the host doesn't have an actstore (and isn't going to get one), then use
  # the VIA attribute to store the acts into another store, and retrieve them from there.
  task :use_source do
    @bootstrap_root = '/tmp'
    @act_root = ENV['VIA'] || "http://#{@uri.host}:9088/acts"
    @packages_root = File.expand_path('../../../packages', __FILE__)
    @clown_install_root = '/var/lib/cache/circus/deb'
    @clown_pkg_cache = '/var/lib/cache/circus/pkg'
    @circus_deb_cfg = "deb file://#{@clown_pkg_cache} /"
  end
  task :ensure_targets => [:use_source]
  
  # Ensure that the Clown installation depends on uploading the Clown first
  task :clown_upload => [:ensure_targets, :ensure_root_ssh] do
    @root_ssh.execute do |ssh|
      # In some development scenarios, we symlink clown/lib to a dev install. Package uninstalls sometimes
      # wipe these in unexpected ways - leaving us with no local source code! If we remove it first, then
      # we're safe.
      log_remote_cmd(ssh, "sudo rm -rf /usr/lib/clown/lib")
      
      # Upload all the clown files onto the server into a staging location
      clown_pkg_staging = '/tmp/clown'
      log_remote_cmd(ssh, "sudo rm -rf #{clown_pkg_staging}")
      log_remote_cmd(ssh, "mkdir -p #{clown_pkg_staging}")
      scp = create_scp(ssh)
      Dir["#{@packages_root}/debs/*"].each do |f|
        scp.upload!(f, clown_pkg_staging)
      end
      
      # Move the staged files to somewhere that will last a reboot
      log_remote_cmd(ssh, "sudo rm -rf #{@clown_pkg_cache}")
      log_remote_cmd(ssh, "sudo mkdir -p #{File.dirname(@clown_pkg_cache)}")
      log_remote_cmd(ssh, "sudo mv #{clown_pkg_staging} #{@clown_pkg_cache}")
    end
  end
  task :clown => :clown_upload
  
  # Make all acts depend on uploading the files first
  BOOTSTRAP_ACTS.each do |name| 
    task "#{name}_upload" do
      act_fn = act_name_with_arch(name)
      
      @ssh.execute do |ssh|
        scp = create_scp(ssh)
        ssh.exec!("sudo rm -f #{@bootstrap_root}/#{act_fn}.act")
        scp.upload!("#{@packages_root}/acts/#{act_fn}.act", "#{@bootstrap_root}/#{act_fn}.act")
      end
    end
    task name => "#{name}_upload"
  end
  ACTS.each do |name| 
    task "#{name}_upload" do
      act_fn = act_name_with_arch(name)
      sh "#{@circus_tool} upload #{@packages_root}/acts/#{act_fn}.act --actstore #{@act_root}"
    end
    task name => "#{name}_upload" 
  end
end

def create_scp(ssh)
  if ssh.respond_to? :session
    Net::SCP.new(ssh.session)
  else
    Net::SCP.new(ssh)
  end
end