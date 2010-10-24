module Nginx
  class Worker
    def initialize(config)
      @config = config
    end

    def forward_hostname(hostname, target, app_root, logger)
      unless app_root
        app_root = '/var/www/no-root-dir'
      end
      
      config = <<-EOT
      server {
        listen 80;
        server_name #{hostname};
        root #{app_root};
        
        
        location / {
          if (-f $request_filename) {
            break;
          }
        
          proxy_set_header Host $host;
          if (!-f $request_filename) {
            proxy_pass  http://#{target};
          }
        }
      }
      EOT
      
      File.open(File.join(@config.config_dir, "#{hostname}.conf"), 'w') do |f|
        f.write(config)
      end
      
      # Signal to nginx to reload configuration
      `/etc/init.d/nginx reload`
      
      "ok"
    end
  end
end