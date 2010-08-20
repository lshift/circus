require 'booth/config'

describe Booth::Config do
  it "should load a sample file" do
    l = Booth::Config.new(File.expand_path('../fixtures/sample.config', __FILE__))
    l.act_store.should == 'http://localhost/acts1'
  end
  
  it "should retrieve options from the environment" do
    ENV['DATA_DIR'] = 'some_dir'
    l = Booth::Config.new(File.expand_path('../fixtures/sample.config', __FILE__))
    l.data_dir.should == 'some_dir'
  end
end