require 'booth/worker'
require 'booth/repos/base'
require 'ostruct'
require 'fileutils'

TMP_DIR = File.expand_path('../../tmp', __FILE__)

describe Booth::Worker do
  # Inject a fake SCM
  before :each do
    @config = OpenStruct.new({
      :data_dir => File.join(TMP_DIR, 'data'), 
      :build_dir => File.join(TMP_DIR, 'build'),
      :act_store => 'http://act/store'})

    @fake_scm_instance = stub('Fake SCM instance')

    @fake_scm = stub 'Fake SCM'
    @fake_scm.stub!(:accepts_id?).with('fake').and_return(true)
    @fake_scm.stub!(:new).with(@config).and_return(@fake_scm_instance)
    Booth::Repos::PROVIDERS << @fake_scm
    
    FileUtils.rm_rf(@config.data_dir)
  end
  after :each do
    Booth::Repos::PROVIDERS.delete(@fake_scm)
  end
  
  before :each do
    @connection = stub('connection')
    @worker = Booth::Worker.new(@connection, @config)
    @logger = stub('logger')
    @logger.stub!(:info)
  end
  
  it "should create a new application on request" do
    @fake_scm_instance.should_receive(:create_application).with(
      'testapp', anything(), 'scm://host/path', {:name => 'testapp'}, @logger).and_return(true)
    
    app_id = @worker.create_application('testapp', 'fake', 'scm://host/path', @logger)
    app_id.should_not be_nil
  end
  
  it "should re-use existing applications when the same details are provided" do
    @fake_scm_instance.should_receive(:create_application).with(
      'testapp', anything(), 'scm://host/path', {:name => 'testapp'}, @logger).once.and_return(true)
    
    app_id = @worker.create_application('testapp', 'fake', 'scm://host/path', @logger)
    app_id2 = @worker.create_application('testapp', 'fake', 'scm://host/path', @logger)
    app_id.should == app_id2
  end
  
  it "should generate an SSH key in the home directory if one doesn't exist" do
    old_home = ENV['HOME']
    begin
      ENV['HOME'] = File.join(TMP_DIR, 'home')
      FileUtils.mkdir_p(ENV['HOME'])
      
      key = @worker.get_ssh_key(@logger)
      key.should_not be_empty
    ensure
      ENV['HOME'] = old_home
    end
  end  
  
  it "should reuse an SSH key in the home directory" do
    old_home = ENV['HOME']
    begin
      ENV['HOME'] = File.join(TMP_DIR, 'home')
      FileUtils.mkdir_p(ENV['HOME'])
      
      key = @worker.get_ssh_key(@logger)
      key2 = @worker.get_ssh_key(@logger)
      key.should == key2
    ensure
      ENV['HOME'] = old_home
    end
  end
  
  it "should fail when admission of an unknown application is requested" do
    lambda { @worker.admit('missingapp', 'commitid', nil, @logger) }.should raise_error(Booth::UnknownApplicationException)
  end
  
  it "should build a known application" do
    app_id = register_app('myapp')
    File.open(File.join(@config.data_dir, app_id, 'myapp.rb'), 'w') { |f| f.write('puts "Test"') }
    @fake_scm.stub!(:accepts_dir?).with(anything()).and_return(true)
    @fake_scm_instance.stub!(:prepare).with(app_id, anything(), 'commitid', nil, @logger)
    @fake_scm_instance.stub!(:config_for).with(anything()).and_return({:name => 'myapp'})
    
    act_store_instance = mock('Act Store')
    Circus::ActStoreClient.should_receive(:new).with('http://act/store', @logger).and_return(act_store_instance)
    act_store_instance.should_receive(:upload_act).with(File.join(@config.build_dir, app_id, 'myapp.act'))
    
    uploaded = @worker.admit(app_id, 'commitid', nil, @logger)
    uploaded.should == [{:name => 'myapp', :url => 'http://act/store/myapp.act'}]
  end
  
  def register_app(name)
    @fake_scm_instance.should_receive(:create_application).with(
      name, anything(), anything(), {:name => name}, @logger).and_return(true)
    @worker.create_application(name, 'fake', 'scm://host/path', @logger)
  end
end