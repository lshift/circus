describe Circus::Profiles::Base do
  before :each do
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
    
    @logger = mock('logger')
    @logger.stub!(:info)
    
    @run_dir = File.join(TMP_DIR, 'base-run')
    FileUtils.mkdir_p(@run_dir)
  end
  
  it "should default to packaging the base directory" do
    abase = Circus::Profiles::Base.new('name', 'dir', {})
    abase.package_base_dir?.should be_true
  end
  
  it "should default to having no extra dirs" do
    abase = Circus::Profiles::Base.new('name', 'dir', {})
    abase.extra_dirs.should == []
  end
  
  it "should generate a dev run script using dev run script content" do
    abase = Circus::Profiles::Base.new('name', 'dir', {})
    abase.should_receive(:dev_run_script_content).and_return('ruby -e "done"')
    res = abase.package_for_dev(@logger, @run_dir)
    res.should be_true
    
    run_script = File.join(@run_dir, 'run')
    File.exists?(run_script).should be_true
    File.read(run_script).split("\n").last.should == 'ruby -e "done"'
  end 
   
  it "should generate a deploy run script using deploy run script content" do
    abase = Circus::Profiles::Base.new('name', 'dir', {})
    abase.should_receive(:deploy_run_script_content).and_return('ruby -e "done2"')
    res = abase.package_for_deploy(@logger, @run_dir)
    res.should be_true
    
    run_script = File.join(@run_dir, 'run')
    File.exists?(run_script).should be_true
    File.read(run_script).split("\n").last.should == 'ruby -e "done2"'
  end
  
  
   it "should generate a requirements.yaml when packaging for deploy" do
     abase = Circus::Profiles::Base.new('name', 'dir', {})
     abase.should_receive(:deploy_run_script_content).and_return('ruby -e "done2"')
     res = abase.package_for_deploy(@logger, @run_dir)
     res.should be_true

     resources_yaml = File.join(@run_dir, 'requirements.yaml')
     File.exists?(resources_yaml).should be_true
     YAML::parse(File.read(resources_yaml))
   end
end