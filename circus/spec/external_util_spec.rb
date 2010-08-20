describe Circus::ExternalUtil do
  before :each do
    FileUtils.rm_rf(TMP_DIR)
    FileUtils.mkdir_p(TMP_DIR)
    
    @logger = mock('logger')
  end
  
  it "should execute a provided command" do
    Circus::ExternalUtil.run_external(@logger, 'touch a file', "echo a >#{TMP_DIR}/a")
    File.exists?("#{TMP_DIR}/a").should be_true
  end
  
  it "should log the output of a failed command" do
    @logger.should_receive(:error).with('failing command failed:').once
    @logger.should_receive(:error).with("Err\n").once
    
    Circus::ExternalUtil.run_external(@logger, 'failing command', "ruby -e \"puts 'Err'; exit 1\"")
  end
end