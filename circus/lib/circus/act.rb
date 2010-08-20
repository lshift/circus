require 'fileutils'
require 'yaml'

module Circus
  class Act
    attr_reader :name, :dir, :props, :profile
    
    def initialize(name, dir, props = {})
      @name = name
      @dir = dir
      @props = props
      
      # Merge act specific properties
      if File.exists? act_file
        act_cfg = YAML.load(File.read(act_file))
        @props.merge! act_cfg
      end
    end
    
    def should_package?
      return false if @props['no-package']
      true
    end
    
    def detect!
      # Run each profile against the directory to try to find one that matches
      profile_clazz = Circus::Profiles::PROFILES.find { |p| p.accepts?(@name, @dir, @props) }
      raise "No profile can run #{@dir}" unless profile_clazz
      
      @profile = profile_clazz.new(@name, @dir, @props)
    end
    
    def package_for_dev(logger, run_root_dir)
      detect! unless @profile
      
      # Create our run directory, and tell the profile to package into it
      run_dir = File.join(run_root_dir, @name)
      FileUtils.mkdir_p run_dir
      profile.package_for_dev(logger, run_dir)
    end
    
    def assemble(logger, output_root_dir, overlay_root)
      detect! unless @profile
      
      overlay_dir = File.join(overlay_root, name)
      FileUtils.mkdir_p(overlay_dir)
      return false unless profile.package_for_deploy(logger, overlay_dir)
      
      begin
        # Squash the output file
        include_dirs = ["#{overlay_dir}/*"]
        include_dirs << "#{@dir}/*" if profile.package_base_dir?
        include_dirs.concat(profile.extra_dirs)
        output_name = File.join(output_root_dir, "#{name}.act")
      
        ExternalUtil.run_external(logger, 'Output packaging', 
          "mksquashfs #{include_dirs.join(' ')} #{output_name} -noappend -noI -noD -noF 2>&1")
      ensure
        profile.cleanup_after_deploy(logger, overlay_dir)
      end
    end
    
    def upload(output_root_dir, act_store)
      detect! unless @profile

      output_name = File.join(output_root_dir, "#{name}.act")
      act_store.upload_act(output_name)
    end
    
    def act_file
      File.join(@dir, 'act.yaml')
    end
  end
end