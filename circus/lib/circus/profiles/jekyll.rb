require File.expand_path('../base', __FILE__)

module Circus
  module Profiles
    class Jekyll < Base
      # Checks if this is a Jekyll site based on whether there is a file named
      # _config.yml on the root directory
      def self.accepts?(name, dir, props)
        return File.exists?(File.join(dir, "_config.yml"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
      end
      
      # The name of this profile
      def name
        "jekyll"
      end

      def package_base_dir?
        false
      end
      
      def extra_dirs
        ["#{@dir}/_site"]
      end

      def prepare_for_deploy(logger, overlay_dir)
        run_external(logger, 'Generate site with Jekyll', "cd #{@dir}; jekyll")

        # Create lighttpd.conf
        File.open(File.join(overlay_dir, 'lighttpd.conf'), 'w') do |f|
            f.write <<-EOT
server.document-root = "_site/" 

server.port = env.HTTPD_PORT

mimetype.assign = (
  ".html" => "text/html", 
  ".txt" => "text/plain",
  ".css" => "text/css",
  ".jpg" => "image/jpeg",
  ".png" => "image/png"
)

static-file.exclude-extensions = ( ".yaml" )
index-file.names = ( "index.html" )
            EOT
        end
        true
      end

      def cleanup_after_deploy(logger, overlay_dir)
        FileUtils.rm_rf(File.join(@dir, '_site'))
      end

      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec jekyll --auto --server
          EOT
        end
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec lighttpd -D -f lighttpd.conf
          EOT
        end
      end

      # Describes the resources required by the deployed application. Jekyll sites automatically
      # require a port to serve content on.
      def requirements
        res = super
          
        # TODO: The clown should be able to automatically allocate listening ports
        res['system-properties'] ||= {}
        res['system-properties']['HTTPD_PORT'] = 3000
        
        res
      end
    end
    
    PROFILES << Jekyll
  end
end
