module Circus
  module Repos
    class Mercurial
      # Checks if the current directory (or a parent) are Hg working trees. Uses
      # a call to hg status to test (which will fail with a non-zero exit if the
      # tree isn't a valid git tree)
      def self.accepts_dir? dir_name
        `hg st >/dev/null 2>/dev/null`
        $? == 0
      end
      
      def self.accepts_id?(key)
        key == 'hg' || key == 'mercurial'
      end
      
      def self.type_id
        'hg'
      end
      
      def initialize(dir)
        @dir = dir
      end
      
      def repo_url
        first_path = `(cd #{@dir}; hg paths)`.lines.first
        return nil unless first_path
        
        first_path.split('=', 2)[1].strip
      end
      
      def current_revision
        `(cd #{@dir}; hg id -i)`[0..11]
      end
      
      def write_patch(patch_fn)
        `(cd #{@dir}; hg diff >#{patch_fn})`.strip
      end
    end
    
    REPOS << Mercurial
  end
end