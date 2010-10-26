module Circus
  module Repos
    class Git
      # Checks if the current directory (or a parent) are Git working trees. Uses
      # a call to git remote to test (which will fail with a non-zero exit if the
      # tree isn't a valid git tree)
      def self.accepts_dir? dir_name
        `git remote >/dev/null 2>/dev/null`
        $? == 0
      end
      
      def self.accepts_id?(key)
        key == 'git'
      end
      
      def self.type_id
        'git'
      end
      
      def initialize(dir)
        @dir = dir
      end
      
      def repo_url
        first_remote = `(cd #{@dir}; git remote -v) | grep fetch`.lines.first
        return nil unless first_remote
        
        first_remote.split(' ', 2)[1].gsub('(fetch)', '').strip
      end
      
      def current_revision
        result = `(cd #{@dir}; git rev-parse HEAD)`
        return result.strip unless $?.exitstatus != 0
      end
      
      def write_patch(patch_fn)
        `(cd #{@dir}; git diff HEAD >#{patch_fn})`.strip
      end
    end
    
    REPOS << Git
  end
end