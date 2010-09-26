require 'vagrant'

require 'rake/remote.tasks'

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

namespace :packaging do
  task :clean do
    rm_rf 'packages/'
  end
  
  desc "Ensures that the packaging vm is available"
  task :ensure_packaging_vm do
    # Load a Vagrant environment for packaging, and ensure that it is available
    @packaging_env = Vagrant::Environment.load!(File.expand_path('../servers/packaging', __FILE__))
    @packaging_env.commands.subcommand 'up', 'packaging32'
    @packaging_env.commands.subcommand 'up', 'packaging64'
  end
 
  task :circus_tools_gem => [:ensure_packaging_vm] do
    @packaging_env.vms[:packaging32].ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)

      log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir /tmp/circus-pkg")
      scp.upload!('circus', '/tmp/circus-pkg', :recursive => true)

      log_remote_cmd(ssh, 'cd /tmp/circus-pkg/circus; rm -rf /tmp/circus-pkg/circus/pkg; rake package')
      mkdir_p 'packages/gems'
      scp.download!('/tmp/circus-pkg/circus/pkg/*.gem', 'packages/gems')
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
 
  task :ensure_working_circus_tools => [:ensure_packaging_vm, :circus_tools_gem] do
    install_circus_tools(@packaging_env, :packaging32)
  end
  
  task :ensure_working_circus_tools64 => [:ensure_packaging_vm] do
    install_circus_tools(@packaging_env, :packaging64)
  end
  
  task :clown => [:ensure_packaging_vm] do
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

  task :debian_repo => [:ensure_packaging_vm] do
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
  
  {
    :actstore => 'actstore', :booth => 'booth', 
    :postgres_tamer => 'tamers/postgres', :nginx_tamer => 'tamers/nginx'
  }.each do |task_name, act_dir|
    task "#{task_name}" => [:ensure_packaging_vm, :ensure_working_circus_tools] do
      package_component(@packaging_env, act_dir, :packaging32, 'i386')
    end
    task "#{task_name}64" => [:ensure_packaging_vm, :ensure_working_circus_tools64] do
      package_component(@packaging_env, act_dir, :packaging64, 'x64')
    end
  end
 
  task :acts => [:actstore, :booth, :postgres_tamer, :nginx_tamer]
  task :acts64 => [:actstore, :booth, :postgres_tamer, :nginx_tamer].map { |n| "#{n}64" } 
  task :all => [:clown, :debian_repo, :acts, :acts64]
end

namespace :deployment do
  task :ensure_node_vm do
    # Load a Vagrant environment for deployment, and ensure that it is available
    @node_env = Vagrant::Environment.load!(File.expand_path('../servers/node', __FILE__))
    @node_env.commands.subcommand 'up'
  end
  task :ensure_ssh_agent => [:ensure_node_vm] do
    sh "ssh-add #{@node_env.config.ssh.private_key_path}"
  end

  task :clown => [:ensure_node_vm] do
    execute_ssh(@node_env, "sudo rm -rf /usr/lib/clown/lib")
    execute_ssh(@node_env, "sudo apt-get remove clown --purge -y --force-yes")
    execute_ssh(@node_env, "(cd /packages/debs; dpkg-scanpackages . /dev/null | gzip -c9 > Packages.gz)")
    execute_ssh(@node_env, "sudo apt-get update")
    execute_ssh(@node_env, "sudo apt-get install clown -y --force-yes")
  end
  
  task :actstore => [:ensure_node_vm, :ensure_ssh_agent] do
    @node_env.vms[:default].ssh.upload!('packages/acts/actstore-i386.act', '/tmp/actstore.act')
    sh "circus/bin/circus deploy ssh://vagrant@localhost:22144 actstore /tmp/actstore.act"
  end
  
  {:booth => 'booth', :postgres_tamer => 'postgres', :nginx_tamer => 'nginx'}.each do |task_name, act_name|
    task task_name => [:ensure_node_vm, :ensure_ssh_agent] do
      deploy_component act_name
    end
  end
  
  task :all_acts => [:actstore, :booth, :postgres_tamer, :nginx_tamer]
  task :all => [:clown, :all_acts]
end

namespace :development do
  namespace :clown do
    desc 'Installs a clown onto the node vm, then changes the source directories to use the local lib'
    task :activate_dev => ['deployment:clown'] do
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

def package_component(env, dir_name, vm_id, suffix)
  root_dir = dir_name.split('/').first
  act_name = File.basename(dir_name)
 
  env.vms[vm_id].ssh.execute do |ssh|
    scp = Net::SCP.new(ssh.session)

    log_remote_cmd(ssh, "rm -rf /tmp/circus-pkg; mkdir /tmp/circus-pkg")
    scp.upload!(root_dir, '/tmp/circus-pkg', :recursive => true)
    scp.upload!('circus', '/tmp/circus-pkg', :recursive => true)

    log_remote_cmd(ssh, "cd /tmp/circus-pkg/#{dir_name} && circus assemble --output /tmp/packages/acts")

    mkdir_p 'packages/acts'
    scp.download!("/tmp/packages/acts/#{act_name}.act", "packages/acts/#{act_name}-#{suffix}.act")
  end
end

def deploy_component(name)
  sh "circus/bin/circus upload packages/acts/#{name}-i386.act --actstore http://192.168.11.5:9088/acts"
  sh "circus/bin/circus deploy ssh://vagrant@localhost:22144 #{name} http://192.168.11.5:9088/acts/#{name}-i386.act"
end
