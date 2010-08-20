require 'bundler'

module Bundler
  class CircusUtil
    def self.fix_external_paths(dir)
      ENV['BUNDLE_GEMFILE'] = File.join(dir, 'Gemfile')
      
      # Correct any path based components in the Gemfile
      full_dir = File.expand_path(dir)
      gem_cache_dir = File.join(dir, 'vendor', 'gems')
      definition = Bundler.definition
      required_updates = []
      definition.sources.select { |s| s.is_a? Bundler::Source::Path }.each do |p|
        unless p.path.to_s.start_with? full_dir
          FileUtils.mkdir_p(gem_cache_dir)
          FileUtils.cp_r(p.path, File.join(gem_cache_dir, p.path.basename.to_s))
         
          if p.is_a? Bundler::Source::Git
            required_updates << {:old => /git .*#{p.uri}.*/, :new => "path \"vendor/gems/#{p.path.basename.to_s}\""}
          else
            required_updates << {:old => p.options['path'], :new => "vendor/gems/#{p.path.basename.to_s}"}
          end
        end
      end
      if required_updates.length > 0
        FileUtils.cp "#{dir}/Gemfile", "#{dir}/Gemfile.circus_orig"
        gf_content = File.read("#{dir}/Gemfile")
        required_updates.each do |u|
          gf_content.gsub!(u[:old], u[:new])
        end
        File.open("#{dir}/Gemfile", 'w') do |f|
          f.write(gf_content)
        end
      end
    end
    
    def self.unfix_external_paths(dir)
      if File.exists? "#{dir}/Gemfile.circus_orig"
        FileUtils.mv "#{dir}/Gemfile.circus_orig", "#{dir}/Gemfile"
      end
    end
  end
end
