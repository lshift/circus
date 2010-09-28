require 'rexml/document'
require 'erb'

module Circus
  module Profiles
    class MavenWebApp < Base
      MAVEN_WEBAPP_PROPERTY='maven-webapp'
      
      # Checks if this is a shell applcation. Will accept the application if it 
      # has a file named <name>.sh, or has a 'shell-app' property describing the entry point.
      def self.accepts?(name, dir, props)
        pom_path = File.join(dir, "pom.xml")
        
        return true if props.include? MAVEN_WEBAPP_PROPERTY
        return false unless File.exists?(pom_path)
        
        pom_content = REXML::Document.new(File.new(pom_path))
        packaging_el = pom_content.root.elements['packaging']
        return false unless packaging_el
        
        packaging_el.text.strip == 'war'
      end
      
      attr_reader :app_final_name
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @app_final_name = props[MAVEN_WEBAPP_PROPERTY] || detect_app_name
      end
      
      # The name of this profile
      def name
        "maven-war"
      end
      
      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec mvn jetty:run
          EOT
        end
      end

      def prepare_for_deploy(logger, overlay_dir)
        # Build the maven package, then copy the output into the overlay directory
        logger.info("Building maven application #{@name}")
        return false unless run_external(logger, 'Perform maven packaging', "cd #{@dir}; mvn package")
        
        logger.info("Expanding artifact #{app_final_name}.war")
        final_full_path = File.expand_path("target/#{app_final_name}.war")
        return false unless run_external(logger, 
          'Expand application artifact', "mkdir #{overlay_dir}/#{@name} && unzip target/#{app_final_name}.war -d #{overlay_dir}/#{@name}/")
        
        logger.info("Generating configuration files for #{@name}")
        write_template('maven_webapp_jetty.xml.erb', "#{overlay_dir}/jetty.xml")
        write_template('maven_webapp_jetty_app.xml.erb', "#{overlay_dir}/jetty-app.xml")
        File.open("#{overlay_dir}/jetty.properties", 'w') do |f|
          f << "jetty.home=/opt/jetty-7.1"
        end
        
        true
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec java -jar /opt/jetty-7.1/start.jar -Djetty.home=/opt/jetty-7.1 OPTIONS=Server,plus,jndi `pwd`/jetty.properties `pwd`/jetty.xml  `pwd`/jetty-app.xml
          EOT
        end
      end
      
      def package_base_dir?
        false
      end
      
      private
        def listen_port
          @props['web-app-port'] || 6000
        end
        
        def amqp_connection_factories
          @props['amqp-connections'] || []
        end
        def datasources
          @props['datasources'] || []
        end
        def env_entries
          @props['env-entries'] || []
        end
      
        def detect_app_name
          effective_pom_path = "/tmp/#{name}-effective.pom"
          `cd #{@dir}; mvn help:effective-pom -Doutput=#{effective_pom_path}`
          unless $? == 0
            raise "Failed to determine effective pom for maven webapp act #{name}"
          end
          
          pom_content = REXML::Document.new(File.new(effective_pom_path))
          pom_content.root.elements['build/finalName'].text.strip
        end
        
        def write_template(template_name, out_name)
          template_path = File.expand_path("../#{template_name}", __FILE__)
          template_erb = ERB.new(File.read template_path)
          template_erb.filename = template_path
          File.open(out_name, 'w') do |f|
            f.write(template_erb.result(binding))
          end
        end
    end
    
    PROFILES << MavenWebApp
  end
end