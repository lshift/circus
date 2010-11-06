## Specs for validating the various deployment types that Circus should be able to handle
require 'fileutils'

describe 'Circus' do
  include FileUtils
  
  CIRCUS_BIN="#{`pwd`.strip}/circus/bin/circus"
  
  it "should be able to deploy Ruby Rack applications" do
    quiet_sh "#{CIRCUS_BIN} admit prod rack"
    content = wait_for_url 'http://192.168.11.10:10531/'
    
    content.should == 'Hello World'
  end
  
  #
  # Support
  #
  
  before :all do
    # Copy all of the examples to a clean temp directory
    rm_rf 'tmp/deploytest'
    mkdir_p 'tmp/deploytest'
    mkdir_p 'tmp/deploytest/repo'
    cp_r 'examples/', 'tmp/deploytest'
    
    # Work in the deploytest directory
    cd 'tmp/deploytest/examples'
    
    # Initial a git repo in this directory so we can clone from it remotely
    quiet_sh 'git init'
    quiet_sh 'git add .'
    quiet_sh 'git commit -m "Initial commit"'
    quiet_sh 'git remote add origin git://192.168.11.1/circus-examples'
    
    # Setup the repo
    quiet_sh 'cd ../repo && git init --bare circus-examples'
    
    # Start up the git daemon
    @child_pid = fork do
      cd '../repo/'
      exec 'git daemon --reuseaddr --base-path=. --export-all --enable=receive-pack'
    end
    
    # Wait for it to be ready
    connected = false
    (1..50).each do
      socket = TCPSocket.new('localhost', 9418) rescue nil
      if socket
        connected = true
        socket.close
        break
      end
      
      sleep 0.1
    end
    
    fail 'git-daemon didn\'t start!' unless connected
    
    # Push changes to the repository
    quiet_sh 'git push origin master'
    
    # Connect a booth
    quiet_sh "#{CIRCUS_BIN} connect prod ssh://vagrant@192.168.11.10"
  end
  
  after :all do
    if @child_pid
      # git-daemon starts a child which we need to cleanup manually
      children = []
      `ps -ef | grep "#{@child_pid}" | grep git-daemon`.lines.each do |line|
        parts = line.split(/\s+/)
        if (parts[3] == @child_pid.to_s) then
          children.push parts[2]
        end
      end
    
      sh "kill -INT #{@child_pid}"
      children.each { |child| sh "kill -INT #{child}" }
    end
  end
  
  def sh(cmd)
    Bundler.with_clean_env do
      fail("#{cmd} failed") unless system(cmd)
    end
  end
  
  def quiet_sh(cmd)
    Bundler.with_clean_env do
      ENV['BUNDLE_GEMFILE'] = nil
      ENV['BUNDLE_BIN_PATH'] = nil
      ENV['RUBYOPT'] = nil
      
      res = `#{cmd} 2>&1`
      unless $? == 0
        message = "#{cmd} failed:\n" + res
        fail(message)
      end
    end
  end
  
  def wait_for_url(url)
    (1..20).each do
      begin
        return Net::HTTP.get URI.parse(url)
      rescue
        sleep 0.1
      end
    end
    
    message = "#{url} never became available"
    fail message
  end
end