require File.expand_path('../env', __FILE__)
require 'circus/agents/logger'

describe Circus::Agents::XMPPLogger do
  before :each do
    @messages = []
    @writer = Proc.new { |m| @messages << m }
  end
  
  it "should send events to the appropriate to target" do
    logger = Circus::Agents::XMPPLogger.new('target@localhost/aaa', 'thread1', @writer)
    logger.info('Hello World')
    
    @messages.length.should == 1
    @messages[0].to.should == 'target@localhost/aaa'
  end  
  
  it "should send the message in the body" do
    logger = Circus::Agents::XMPPLogger.new('target@localhost', 'thread1', @writer)
    logger.info('Hello World')
    
    @messages.length.should == 1
    @messages[0].body.should == 'Hello World'
  end
  
  it "should include the thread" do
    logger = Circus::Agents::XMPPLogger.new('target@localhost', 'thread1', @writer)
    logger.info('Hello World')
    
    @messages.length.should == 1
    @messages[0].thread.should == 'thread1'
  end
  
  it "should prefix errors with 'ERROR'" do
    logger = Circus::Agents::XMPPLogger.new('target2@localhost', 'thread1', @writer)
    logger.error('Wrong')
    
    @messages.length.should == 1
    @messages[0].to.should == 'target2@localhost'
    @messages[0].body.should == 'ERROR: Wrong'
  end
  
  it "should send an ok message and a gone message when call is marked as completed" do
    logger = Circus::Agents::XMPPLogger.new('target3@localhost', 'thread1', @writer)
    logger.complete
    
    @messages.length.should == 2
    @messages[0].to.should == 'target3@localhost'
    @messages[0].body.should == 'ok'
    @messages[1].to.should == 'target3@localhost'
    @messages[1].xpath('ns:gone', 'ns' => 'http://jabber.org/protocol/chatstates').should_not be_nil
  end  
  
  it "should send an ok message with the result when a result is provided" do
    logger = Circus::Agents::XMPPLogger.new('target3@localhost', 'thread1', @writer)
    logger.complete(:a => 1)
    
    @messages.length.should == 2
    @messages[0].to.should == 'target3@localhost'
    @messages[0].body.should == 'ok a=1'
    @messages[1].to.should == 'target3@localhost'
    @messages[1].xpath('ns:gone', 'ns' => 'http://jabber.org/protocol/chatstates').should_not be_nil
  end  
  
  it "should send a failed message when the operation fails" do
    logger = Circus::Agents::XMPPLogger.new('target3@localhost', 'thread1', @writer)
    logger.failed('some reason')
    
    @messages.length.should == 2
    @messages[0].to.should == 'target3@localhost'
    @messages[0].body.should == 'failed some reason'
    @messages[1].to.should == 'target3@localhost'
    @messages[1].xpath('ns:gone', 'ns' => 'http://jabber.org/protocol/chatstates').should_not be_nil
  end
  
  it "should allocate a thread when it is nil" do
    logger = Circus::Agents::XMPPLogger.new('target@localhost', nil, @writer)
    logger.info('Hello World')
    
    @messages.length.should == 1
    @messages[0].thread.should_not be_nil
  end
end