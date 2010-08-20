require 'circus/profiles/jekyll'
require File.expand_path('../shared', __FILE__)

describe Circus::Profiles::Jekyll do
  before :all do
    @profile_clazz = Circus::Profiles::Jekyll
  end
  
  it_should_behave_like 'an assembly profile'
end
