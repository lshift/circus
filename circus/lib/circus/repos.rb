module Circus
  module Repos
    REPOS=[]
    
    def self.find_repo_from_dir(dir_name)
      REPOS.find { |r| r.accepts_dir? dir_name }
    end
    
    def self.find_repo_by_id(type_name)
      REPOS.find { |r| r.accepts_id? type_name }
    end
  end
end

require File.expand_path('../repos/git', __FILE__)
require File.expand_path('../repos/mercurial', __FILE__)