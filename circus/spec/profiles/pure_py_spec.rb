require 'circus/profiles/pure_py'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::PurePy do
  before :all do
    @profile_clazz = Circus::Profiles::PurePy
  end
  
  it_should_behave_like 'an assembly profile'
end