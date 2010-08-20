require File.expand_path('../env', __FILE__)
require 'circus/agents/encoding'

describe Circus::Agents::Encoding do
  it 'should encode a hash of parameters' do
    Circus::Agents::Encoding.encode(:a => 123).should == 'a=123'
  end
  
  it 'should encode list values into multiple arguments' do
    Circus::Agents::Encoding.encode(:a => [1,'ab',3]).should == 'a=1&a=ab&a=3'
  end
  
  it 'should decode a single entry into a single value' do
    Circus::Agents::Encoding.decode('a=1').should == {'a' => '1'}
  end
  
  it 'should decode multiple values into a list' do
    Circus::Agents::Encoding.decode('act=a&act=b').should == {'act' => ['a', 'b']}
  end
end