require File.expand_path('../env', __FILE__)
require 'circus/agents/agent'
require 'circus/agents/client'

describe Circus::Agents::Agent do
  before :each do
    @messages = []
    @connection = StubConnection.new(RecordStream.new(@messages))
  end
  
  it "should allow for commands with no parameters to be declared" do
    a = SpecAgent.new(@connection)
    @connection.send_message('ping', 'client@localhost')
    
    @messages.length.should == 2
    @messages[0].body.should == 'ok'
    Circus::Agents::Conversation.ended?(@messages[1]).should be_true
  end
  
  it "should allow for commands with required parameters to be declared" do
    a = SpecAgent.new(@connection)
    @connection.send_message('create name=1', 'client@localhost')
    
    @messages.length.should == 2
    @messages[0].body.should == 'ok result_name=1'
    Circus::Agents::Conversation.ended?(@messages[1]).should be_true
  end
  
  it "should allow for commands with required parameters to be declared" do
    a = SpecAgent.new(@connection)
    @connection.send_message('create2 name=1', 'client@localhost')
    @connection.send_message('create2 name=1&other_name=2', 'client@localhost')
    
    @messages.length.should == 4
    @messages[0].body.should == 'ok result2_name=1'
    @messages[2].body.should == 'ok result2_name=2'
  end
  
  it "should not invoke a command when a partial name match is made" do
    a = SpecAgent.new(@connection)
    @connection.send_message('created name=1', 'client@localhost')
    
    @messages.length.should == 0
  end
  
  describe "with #{Circus::Agents::Client}" do
    before :each do
      @client_send = SendStream.new
      @client_connection = StubConnection.new(@client_send)
      
      @agent_send = SendStream.new
      @agent_connection = StubConnection.new(@agent_send)

      @agent_send.connection = @client_connection
      @client_send.connection = @agent_connection
      
      @agent = SpecAgent.new(@agent_connection)
      @client = Circus::Agents::Client.new(@client_connection)
    end
    
    it "should support calling a no-args method" do
      logs = []
      res = @client.call('agent@test', 'ping', {}) do |m|
        logs << m if m.body
      end.result
      
      logs.length.should == 1
      logs[0].body.should == 'ok'
      res.should == nil
    end
    
    it "should support returning the result provided by the agent" do
      logs = []
      res = @client.call('agent@test', 'create', {:name => 'a'}) do |m|
        logs << m if m.body
      end.result
      
      logs.length.should == 1
      res.should == {'result_name' => 'a'}
    end
  end
end

class StubConnection < Circus::Agents::Connection
  def initialize(stream)
    super()
    
    @stream = stream
  end
  
  # No-op for run
  def run
  end
  
  def stream
    @stream
  end
  
  def send_message(s, from)
    msg = Blather::Stanza::Message.new('agent@test', s)
    msg.from = from
    handle_stanza(msg)
  end
  def send_stanza(s)
    handle_stanza(s)
  end
end

class RecordStream
  def initialize(messages)
    @messages = messages
  end
  
  def send(stanza)
    @messages << stanza
  end
end
class SendStream
  attr_accessor :connection
  
  def send(stanza)
    connection.send_stanza(stanza)
  end
end

class SpecAgent < Circus::Agents::Agent
  command 'ping' do |params, logger|
    logger.complete
  end
  
  command 'create' do |params, logger|
    name = params.required('name')
    
    logger.complete(:result_name => name)
  end
  
  command 'create2' do |params, logger|
    name = params.required('name')
    other_name = params.optional('other_name')
    
    logger.complete(:result2_name => other_name || name)
  end
end