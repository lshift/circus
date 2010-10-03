require 'vagrant'

task :spec do
  ['circus', 'clown', 'booth'].each do |r|
    sh "cd #{r}; rake spec"
  end
end

namespace :docs do
  task :ensure_jekyll_and_deps do
    begin
      require 'jekyll'
    rescue LoadError
      fail "Jekyll needs to be installed to generate the documentation. Run sudo gem install jekyll"
    end
    `pygmentize`
    if $? != 0
      fail "Pygments needs to be installed to generate the documentation. Run sudo easy_install pygments"
    end
  end
  
  task :generate => :ensure_jekyll_and_deps do
    sh 'cd docs; jekyll'
  end

  task :server => :ensure_jekyll_and_deps do
    sh 'cd docs; jekyll --auto --server'
  end
end
task :docs => ['docs:generate']

ALL_APP_ACTS = {
  :actstore => 'actstore', :booth => 'booth', 
  :postgres_tamer => 'tamers/postgres', :nginx_tamer => 'tamers/nginx'
}
ALL_STACKS = [:booth_support, :database, :erlang, :java_web, :python, :ruby, :static_web, :web]

namespace :packaging do
  task :clean do
    rm_rf 'packages/'
  end
  
  task :ensure_packaging_env do
    @packaging_env = Vagrant::Environment.new(:cwd => File.expand_path('../servers/packaging', __FILE__))
    @packaging_env.ui = Vagrant::UI::Shell.new(@packaging_env, Thor::Base.shell.new)
    @packaging_env.load!
    # load!(File.expand_path('../servers/packaging', __FILE__))
  end
  
  desc "Ensures that the 32 bit packaging vm is available"
  task :ensure_packaging_vm32 => :ensure_packaging_env do
    @packaging_env.cli('up', 'packaging32')
  end

  task :ensure_packaging_vm64 => :ensure_packaging_env do
    @packaging_env.cli('up', 'packaging64')
  end
 
  task :circus_tools_gem => [:ensure_packaging_vm32] do
    @packaging_env.vms[:packaging32].ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)

      log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir /tmp/circus-pkg")
      scp.upload!('circus', '/tmp/circus-pkg', :recursive => true)

      log_remote_cmd(ssh, 'cd /tmp/circus-pkg/circus; rm -rf /tmp/circus-pkg/circus/pkg; rake package')
      gem_path = ssh.exec!('ls /tmp/circus-pkg/circus/pkg/circus-deployment-*.gem').strip
      mkdir_p 'packages/gems'
      scp.download!(gem_path, 'packages/gems')
    end
  end

  def install_circus_tools(env, vm_id)
    env.vms[vm_id].ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)

      gem_name = File.basename(Dir['packages/gems/*.gem'].first)
      scp.upload!("packages/gems/#{gem_name}", '/tmp')
      log_remote_cmd(ssh, "sudo gem install /tmp/#{gem_name} --no-ri --no-rdoc")
    end
  end
 
  task :ensure_working_circus_tools => [:ensure_packaging_vm32, :circus_tools_gem] do
    install_circus_tools(@packaging_env, :packaging32)
  end
  
  task :ensure_working_circus_tools64 => [:ensure_packaging_vm64] do
    install_circus_tools(@packaging_env, :packaging64)
  end
  
  task :clown => [:ensure_packaging_vm32] do
    # Upload the Clown build files
    @packaging_env.vms[:packaging32].ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)

      log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir /tmp/circus-pkg")
      scp.upload!('clown', '/tmp/circus-pkg', :recursive => true)
      scp.upload!('circus', '/tmp/circus-pkg', :recursive => true)

      # Execute the build of the clown
      version_str = if ENV['VERSION'] then "VERSION=#{ENV['VERSION']}" else '' end
      log_remote_cmd(ssh, "make -C /tmp/circus-pkg/clown package #{version_str}")

      # Download the packaged files
      rm_rf 'packages/debs'
      rm_rf 'packages/tmp'
      mkdir_p 'packages'
      scp.download!('/tmp/circus-pkg/clown/build', 'packages/tmp', :recursive => true)
      mv 'packages/tmp/build', 'packages/debs'
    end
  end

  task :debian_repo => [:ensure_packaging_vm32] do
    mkdir_p 'packages'

    # Execute the build of the clown
    @packaging_env.vms[:packaging32].ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)

      log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir -p /tmp/circus-pkg/packages")
      scp.upload!('packages/debs', '/tmp/circus-pkg/packages', :recursive => true)
      scp.upload!('debian', '/tmp/circus-pkg', :recursive => true)

      # Execute the build of the repo
      log_remote_cmd(ssh, "make -C /tmp/circus-pkg/debian")

      # Download the repository
      rm_rf 'packages/debian'
      scp.download!('/tmp/circus-pkg/packages/debian', 'packages/', :recursive => true)
    end
  end
  
  ALL_APP_ACTS.each do |act_name, act_dir|
    task "#{act_name}" => [:ensure_packaging_vm32, :ensure_working_circus_tools] do
      package_component(@packaging_env, act_dir, act_name, :packaging32, 'i386')
    end
    task "#{act_name}64" => [:ensure_packaging_vm64, :ensure_working_circus_tools64] do
      package_component(@packaging_env, act_dir, act_name, :packaging64, 'x64')
    end
  end
  
  ALL_STACKS.each do |stack_name|
    task "#{stack_name}_stack" => [:ensure_packaging_vm32, :ensure_working_circus_tools] do
      package_component(@packaging_env, "stacks/#{stack_name}", "#{stack_name}_stack", :packaging32)
    end
  end
 
  task :acts => ALL_APP_ACTS.keys
  task :acts64 => ALL_APP_ACTS.keys.map { |n| "#{n}64" } 
  task :stacks => ALL_STACKS.map { |n| "#{n}_stack" }
  task :all => [:clown, :debian_repo, :acts, :acts64, :stacks]
end

# For installation, use the node build via the Fasttrack, and apply the source installation changes
load 'fasttrack/Rakefile'
require 'installer/tasks/source_install.tasks'

namespace :development do
  namespace :clown do
    desc 'Installs a clown onto the node vm, then changes the source directories to use the local lib'
    task :activate_dev => ['install:clown'] do
      execute_ssh(@node_env, "sudo rm -r /usr/lib/clown/lib/")
      execute_ssh(@node_env, "sudo ln -s /circus/clown/lib /usr/lib/clown/lib")
    end

    task :restart => ['deployment:ensure_node_vm'] do
      execute_ssh(@node_env, "sudo restart svscan || sudo start svscan")
    end
  end
end


namespace :cleanup do
  task :booth => ['deployment:ensure_node_vm', 'deployment:ensure_ssh_agent'] do
    sh "circus/bin/circus undeploy ssh://vagrant@localhost:22144 booth"
  end
end

def execute_ssh(env, command, vm_id = :default)
  env.vms[vm_id].ssh.execute do |ssh|
    log_remote_cmd(ssh, command)
  end
end

def package_component(env, dir_name, act_name, vm_id, arch = nil)
  root_dir = dir_name.split('/').first
 
  suffix = if arch then "-#{arch}" else "" end
  env.vms[vm_id].ssh.execute do |ssh|
    scp = Net::SCP.new(ssh.session)

    log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir /tmp/circus-pkg")
    scp.upload!(root_dir, '/tmp/circus-pkg', :recursive => true)
    scp.upload!('circus', '/tmp/circus-pkg', :recursive => true)

    log_remote_cmd(ssh, "cd /tmp/circus-pkg/#{dir_name} && circus assemble --output /tmp/packages/acts")

    mkdir_p 'packages/acts'
    scp.download!("/tmp/packages/acts/#{act_name}.act", "packages/acts/#{act_name}#{suffix}.act")
  end
end

def deploy_component(name, arch)
  suffix = if arch then "-#{arch}" else "" end
  
  sh "circus/bin/circus upload packages/acts/#{name}#{suffix}.act --actstore http://192.168.11.5:9088/acts"
  sh "circus/bin/circus deploy ssh://vagrant@localhost:22144 #{name} http://192.168.11.5:9088/acts/#{name}#{suffix}.act"
end
