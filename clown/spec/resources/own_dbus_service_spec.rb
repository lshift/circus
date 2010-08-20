require 'clown/resources'
require File.expand_path('../shared', __FILE__)

describe Clown::Resources::OwnDBusService do
  before :all do
    @resource_clazz = Clown::Resources::OwnDBusService
  end
  
  it_should_behave_like 'a clown resource manager'
end