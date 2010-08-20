require 'circus/booth_tool'

describe Circus::BoothTool do
  before :each do
    @config = OpenStruct.new({:booths => {}})
    @logger = stub 'Logger'
    
    @tool = Circus::BoothTool.new(@logger, @config)
  end
  
  it "should generate an error when no booth exists and the default is requested" do
    @logger.should_receive :error, "No booths configured. Please configure a booth with 'connect' first."
    @tool.admit(nil, [], {})
  end
  
  it "should generate an error when an unknown booth is requested" do
    @logger.should_receive :error, "No booth unknown_booth is configured. Configure it first with 'connect'."
    @tool.admit("unknown_booth", [], {})
  end
end