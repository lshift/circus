require 'circus/act'

describe Circus::Act do
  before :each do
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
    
    @logger = mock('logger')
    @logger.stub!(:info)
  end
  
  it "should respond to requests about its name" do
    act = Circus::Act.new('actname', File.join(TMP_DIR, 'myact'), {})
    act.name.should == 'actname'
  end
  
  it "should respond to requests about its dir" do
    act = Circus::Act.new('actname', File.join(TMP_DIR, 'myact'), {})
    act.dir.should == File.join(TMP_DIR, 'myact')
  end
    
  it "should respond to requests about its props" do
    act = Circus::Act.new('actname', File.join(TMP_DIR, 'myact'), {:a => :b})
    act.props.should == {:a => :b}
  end
  
  it "should default to being packaged" do
    act = Circus::Act.new('actname', File.join(TMP_DIR, 'myact'), {:a => :b})
    act.should_package?.should be_true
  end  
  
  it "should default to being packaged" do
    act = Circus::Act.new('actname', File.join(TMP_DIR, 'myact'), {'no-package' => true})
    act.should_package?.should be_false
  end
  
  describe 'with an empty application' do
    before :each do
      @empty_dir = File.join(TMP_DIR, 'emptyact')
      FileUtils.mkdir_p(@empty_dir)
      @empty_act = Circus::Act.new('emptyact', @empty_dir, {:a => :b})
    end
    
    it "it should fail detection" do
      lambda { @empty_act.detect! }.should raise_error
    end
  end
  
  describe 'with a basic ruby application' do
    before :each do
      @ruby_dir = File.join(TMP_DIR, 'rubyact')
      FileUtils.mkdir_p(@ruby_dir)
      File.open(File.join(@ruby_dir, 'rubyact.rb'), 'w') { |f| f.write('puts "Testing"') }
      @ruby_act = Circus::Act.new('rubyact', @ruby_dir, {:a => :b})
      
      @working_dir = File.join(@ruby_dir, '.circus', 'overlay')
      @output_dir = File.join(@ruby_dir, '.circus', 'output')
    end
    
    it "should detect the application" do
      @ruby_act.detect!
    end
  
    it "should support packaging for development" do
      @ruby_act.package_for_dev(@logger, @working_dir)
      File.exists?(File.join(@working_dir, 'rubyact', 'run')).should be_true
    end
    
    it "should support assembly for deployment" do
      Circus::ExternalUtil.should_receive(:run_external).with(anything(), 'Output packaging', anything()).and_return(true)
      
      @ruby_act.assemble(@logger, @output_dir, @working_dir)
    end
  end
end