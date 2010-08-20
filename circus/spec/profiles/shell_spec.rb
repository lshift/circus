require 'circus/profiles/shell'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::Shell do
  before :all do
    @profile_clazz = Circus::Profiles::Shell
  end
  
  it_should_behave_like 'an assembly profile'
end