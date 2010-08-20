require File.expand_path('../python_base', __FILE__)

module Circus
  module Profiles
    class Django < PythonBase
      DJANGO_APP_PROPERTY='django-app'
      
      # Checks if this is a Django application. Will accept the application if it 
      # has a file named manage.py, or has a 'django-app' property describing the entry point.
      def self.accepts?(name, dir, props)
        return true if props.include? DJANGO_APP_PROPERTY
        return File.exists?(File.join(dir, "manage.py"))
      end
      
      def initialize(name, dir, props)
        super(name, dir, props)
        
        @manage_script = props[DJANGO_APP_PROPERTY] || "manage.py"
      end
      
      # The name of this profile
      def name
        "django"
      end
      
      def prepare_for_deploy(logger, overlay_dir)
        return false unless super
        
        File.open(File.join(overlay_dir, 'local_settings.py'), 'w') do |f|
            f.write <<-EOT
import os
            
DATABASE_ENGINE = 'postgresql_psycopg2'
DATABASE_NAME = os.getenv('DATABASE_NAME')
DATABASE_USER = os.getenv('DATABASE_USER')
DATABASE_PASSWORD = os.getenv('DATABASE_PASSWORD')
DATABASE_HOST = os.getenv('DATABASE_HOST')
            EOT
        end
        true
      end

      def dev_run_script_content
        shell_run_script do
          <<-EOT
          cd #{@dir}
          exec vendor/bin/python #{@manage_script} runserver
          EOT
        end
      end

      def deploy_run_script_content
        shell_run_script do
          <<-EOT
          exec vendor/bin/python #{@manage_script} runserver --noreload 0.0.0.0:$LISTEN_PORT
          EOT
        end
      end

      # Describes the requirements of the deployed application. Django applications automatically
      # require a database with accessible credentials.
      def requirements
        res = super

        db_name = @props['database_name'] || @name
        res['resources'] ||= []
        res['resources'] << {
            'type' => 'Postgres',
            'name' => db_name,
            'user' => @props['database_user'] || db_name,
            'password' => @props['database_password'] || db_name
          }
          
        # TODO: The clown should be able to automatically allocate listening ports
        res['system-properties'] ||= {}
        res['system-properties']['LISTEN_PORT'] = 3000
        
        # TODO: The clown should be able to automatically respond with DB details
        res['system-properties']['DATABASE_NAME'] = db_name
        res['system-properties']['DATABASE_USER'] = db_name
        res['system-properties']['DATABASE_PASSWORD'] = @props['database_password'] || db_name
        res['system-properties']['DATABASE_HOST'] = 'localhost'
        
        res
      end
    end
    
    PROFILES << Django
  end
end