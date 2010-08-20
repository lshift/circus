require 'circus/profiles/django'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::Django do
  before :all do
    @profile_clazz = Circus::Profiles::Django
  end
  
  it_should_behave_like 'an assembly profile'
end