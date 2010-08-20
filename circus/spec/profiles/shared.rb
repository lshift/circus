shared_examples_for 'an assembly profile' do
  before :each do
    @profile1 = @profile_clazz.new('test', '/tmp', {})
  end
  
  it "should respond to requests for its name" do
    @profile1.name.should_not be_nil
  end
  
  it "should respond to requests as to whether to package the base dir" do
    [true, false].should include(@profile1.package_base_dir?)
  end
  
  it "should respond to requests for the extra dirs to be packaged" do
    @profile1.extra_dirs.should_not be_nil
  end
  
  it "should respond to requests for requirements" do
    @profile1.requirements.should_not be_nil
  end
end