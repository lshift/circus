require 'circus/profiles/pure_rb'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::PureRb do
  before :all do
    @profile_clazz = Circus::Profiles::PureRb
  end
  
  it_should_behave_like 'an assembly profile'
end