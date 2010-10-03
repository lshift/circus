namespace :install do
  task :use_source do
    @bootstrap_root = '/tmp'
    @act_root = 'http://192.168.11.10:9088/acts'
    @packages_root = File.expand_path('../../../packages', __FILE__)
    @clown_install_root = '/var/lib/cache/circus/deb'
    @circus_deb_cfg = "deb file://#{clown_pkg_cache} /"
  end
  task :ensure_targets => [:use_source]
  
  # Ensure that the Clown installation depends on uploading the Clown first
  task :clown_upload => :ensure_targets do
    @ssh.execute do |ssh|
      # In some development scenarios, we symlink clown/lib to a dev install. Package uninstalls sometimes
      # wipe these in unexpected ways - leaving us with no local source code! If we remove it first, then
      # we're safe.
      log_remote_cmd(ssh, "sudo rm -rf /usr/lib/clown/lib")
      
      # Upload all the clown files onto the server into a staging location
      clown_pkg_staging = '/tmp/clown'
      log_remote_cmd(ssh, "sudo rm -rf #{clown_pkg_staging}")
      log_remote_cmd(ssh, "mkdir -p #{clown_pkg_staging}")
      scp = Net::SCP.new(ssh.session)
      Dir["#{@packages_root}/debs/*"].each do |f|
        scp.upload!(f, clown_pkg_staging)
      end
      
      # Move the staged files to somewhere that will last a reboot
      clown_pkg_cache = '/var/lib/cache/circus/pkg'
      log_remote_cmd(ssh, "sudo rm -rf #{clown_pkg_cache}")
      log_remote_cmd(ssh, "sudo mkdir -p #{File.dirname(clown_pkg_cache)}")
      log_remote_cmd(ssh, "sudo mv #{clown_pkg_staging} #{clown_pkg_cache}")
    end
  end
  task :clown => :clown_upload
  
  # Make all acts depend on uploading the files first
  BOOTSTRAP_ACTS.each do |name| 
    task "#{name}_upload" do
      act_fn = act_name_with_arch(name)
      
      @ssh.execute do |ssh|
        scp = Net::SCP.new(ssh.session)
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