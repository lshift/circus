require 'circus/profiles/rack'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::Rack do
  before :all do
    @profile_clazz = Circus::Profiles::Rack
  end
  
  it_should_behave_like 'an assembly profile'
end