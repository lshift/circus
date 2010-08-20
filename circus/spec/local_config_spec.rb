require 'circus/local_config'
require 'fileutils'

describe Circus::LocalConfig do
  include FileUtils
  ROOT = '/tmp/circus-test'
  
  before :each do
    mkdir_p ROOT
  end
  
  after :each do
    rm_rf ROOT
  end
  
  it "should report being new when pointed at an empty dir hierarchy" do
    mkdir_p "#{ROOT}/empty"
    
    c = Circus::LocalConfig.new "#{ROOT}/empty"
    c.new?.should be_true
  end
  
  it "should not report being new after being saved" do
    mkdir_p "#{ROOT}/saved"
    
    c = Circus::LocalConfig.new "#{ROOT}/saved"
    c.save!
    c.new?.should be_false
  end
  
  it "should not report being new after being loaded from an existing config" do
    mkdir_p "#{ROOT}/exists"
    
    c = Circus::LocalConfig.new "#{ROOT}/exists"
    c.save!
    
    c2 = Circus::LocalConfig.new "#{ROOT}/exists"
    c2.new?.should be_false
  end
  
  it "should save and reload alias configuration" do
    mkdir_p "#{ROOT}/here"
    
    c = Circus::LocalConfig.new "#{ROOT}/here"
    c.aliases['a'] = 'b'
    c.save!
    
    c2 = Circus::LocalConfig.new "#{ROOT}/here"
    c2.aliases['a'].should == 'b'
  end
  
  it "should save and reload booth configuration" do
    mkdir_p "#{ROOT}/here"
    
    c = Circus::LocalConfig.new "#{ROOT}/here"
    c.booths['b'] = {:a => 1, :b => 2}
    c.save!
    
    c2 = Circus::LocalConfig.new "#{ROOT}/here"
    c2.booths['b'].should == {:a => 1, :b => 2}
  end
  
  it "should search parent directories for booth configurations" do
    mkdir_p "#{ROOT}/parent/child"
    
    c = Circus::LocalConfig.new "#{ROOT}/parent"
    c.aliases['a'] = 'b'
    c.save!
    
    c2 = Circus::LocalConfig.new "#{ROOT}/parent/child"
    c2.aliases['a'].should == 'b'
  end
  
  it "should save to same location as the configuration was loaded from" do
    mkdir_p "#{ROOT}/parent/child"
    
    c = Circus::LocalConfig.new "#{ROOT}/parent"
    c.save!
    
    c2 = Circus::LocalConfig.new "#{ROOT}/parent/child"
    c2.aliases['c'] = 'd'
    c2.save!
    
    c3 = Circus::LocalConfig.new "#{ROOT}/parent"
    c3.aliases['c'].should == 'd'
  end
end