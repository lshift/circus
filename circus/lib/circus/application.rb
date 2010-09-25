require 'yaml'
require 'fileutils'

module Circus
  class Application
    attr_reader :acts
    
    def initialize(dir, name = nil)
      @dir = dir
      @name = name || File.basename(dir)
      @acts = nil
    end
    
    def load!
      @acts = if File.exists?(acts_file)
        acts_cfg = YAML.load(File.read(acts_file))
        acts_cfg.map do |name, props|
            # If no props are specified in the YAML, this could be nil. Default it.
          props ||= {}
          
          act_dir = File.join(@dir, props['dir'] || name)
          Act.new(name, act_dir, props)
        end
      else
        [Act.new(@name, @dir)]
      end
    end
    
    # Instructs the application to startup in place and activate all of its associated
    # acts.
    def go!(logger)
      # Ensure that we have svscan available. If we don't, die nice and early
      `which svscan`
      if $? != 0
        logger.error 'The svscan utility (usually provided by daemontools) is not available. ' +
          ' This utility must be installed before the circus go command can function.'
        # TODO: Detect OS and suggest installation mechanism?
          
        return
      end
      
      load! unless @acts
      
      FileUtils.rm_rf(private_run_root)
      acts.each do |act|
        act.package_for_dev(logger, private_run_root)
      end
      acts.each do |act|
        logger.info "Starting act #{act.name} at #{act.dir} using profile #{act.profile.name}"
      end
      logger.info "---------------------"
      
      # If we've loaded bundler ourselves, then we need to remove its environment variables; otherwise,
      # it will screw up child applications!
      ENV['BUNDLE_GEMFILE'] = nil
      ENV['BUNDLE_BIN_PATH'] = nil
      system("svscan #{private_run_root}")
    end
    
    # Instructs the application to stop the given act that is running under development via go.
    def pause(logger, act_name)
      load! unless @acts
      
      target_act = acts.find { |a| a.name == act_name }
      unless target_act
        logger.error "Act #{act_name} could not be found"
        return
      end
      
      target_act.pause(logger, private_run_root)
    end
    
    # Instructs the application to resume the given act that is running under development via go.
    def resume(logger, act_name)
      load! unless @acts
      
      target_act = acts.find { |a| a.name == act_name }
      unless target_act
        logger.error "Act #{act_name} could not be found"
        return
      end
      
      target_act.resume(logger, private_run_root)
    end
    
    # Instructs the application to assemble it's components for deployment and generate
    # act output files.
    def assemble!(output_dir, logger, dev = false, only_acts = nil)
      load! unless @acts

      if dev
        acts.each do |act|
          logger.info "Assembling development act #{act.name} at #{act.dir}"
          act.package_for_dev(logger, private_run_root)
        end
        return true
      end
      
      assembly_acts = acts.select {|a| only_acts.nil? or only_acts.include? a.name }
      
      FileUtils.mkdir_p(output_dir)
      assembly_acts.each do |act|
        act.detect!
        if act.should_package?
          logger.info "Assembling act #{act.name} at #{act.dir} using profile #{act.profile.name}"
        end
      end
      logger.info "---------------------"
      assembly_acts.each do |act|
        if act.should_package?
          return false unless act.assemble(logger, output_dir, private_overlay_root)
        end
      end
      
      true
    end
    
    def upload(output_dir, act_store, only_acts = nil)
      load! unless @acts
      upload_acts = acts.select {|a| only_acts.nil? or only_acts.include? a.name }
      
      upload_acts.each do |act|
        act.upload(output_dir, act_store)
      end
    end
        
    def private_run_root
      File.join(@dir, '.circus', 'run-dev')
    end
    
    def private_overlay_root
      File.join(@dir, '.circus', 'overlays')
    end
    
    def acts_file
      File.join(@dir, 'acts.yaml')
    end
  end
end
