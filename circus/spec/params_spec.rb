require 'circus/agents/params'

describe Circus::Agents::CommandParams do
  it "should support a nil string" do
    Circus::Agents::CommandParams.new(nil)
  end
  
  it "should support a single required parameter" do
    p = Circus::Agents::CommandParams.new('a=hello')
    a = p.required('a')
    a.should == 'hello'
  end
  
  it "should support multiple required parameters" do
    p = Circus::Agents::CommandParams.new('a=hello&b=world')
    a, b = p.required('a', 'b')
    a.should == 'hello'
    b.should == 'world'
  end
  
  it "should return nil when a single missing optional parameter is requested" do
    p = Circus::Agents::CommandParams.new('a=bill')
    b = p.optional('b')
    b.should be_nil
  end
  
  it "should return nil in the appropriate position for a missing optional parameter" do
    p = Circus::Agents::CommandParams.new('a=bob')
    a, b = p.optional('a', 'b')
    a.should == 'bob'
    b.should be_nil
  end
end