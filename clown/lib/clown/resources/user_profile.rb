module Clown
  module Resources
    # Handles requesting that a profile exists for the given user. This is
    # usually used in tandem with the execution-user resource to switch the
    # application to using the given account.
    class UserProfile
      def initialize(config, logger)
        @config = config
        @logger = logger
      end
      
      def update_env(name, resource_data, env)
        if resource_data['user-profile']
          resource_data['user-profile'].each do |u|
            profile_dir = File.join(@config.local_store_path, name, 'profile')
            
            `id #{u} >/dev/null 2>/dev/null`
            if $? != 0
              @logger.info("Creating user and profile for #{u}")
             
              # useradd won't create parent directories - ensure they are in place
              FileUtils.mkdir_p(File.dirname(profile_dir))
              res = `useradd -d #{profile_dir} -m #{u} 2>&1`
              if $? != 0
                @logger.error("Failed to create user profile for #{u}: #{res}")
              end
            end
          end
        end
      end
    end

    RESOURCES << UserProfile
  end
end
