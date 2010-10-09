module Nginx
  class Worker
    def initialize(config)
      @config = config
    end

    def forward_hostname(hostname, target, logger)
      config = <<-EOT
      server {
        listen 80;
        server_name #{hostname};
        
        location / {
          proxy_pass  http://#{target};
          proxy_set_header Host $host;
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