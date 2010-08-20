shared_examples_for 'a clown resource manager' do
  before :each do
  end
  
  it "might respond to requests for configurable props" do
    if @profile_clazz.respond_to? :configurable_props
      @profile_clazz.configurable_props.should_not be_nil
    end
  end
end