require_recipe 'java_sun'

directory "/var/cache/chef/packages" do
  action :create
  recursive true
end
remote_file "/var/cache/chef/packages/jetty-distribution-7.1.6.v20100715.tar.gz" do
  source "http://download.eclipse.org/jetty/7.1.6.v20100715/dist/jetty-distribution-7.1.6.v20100715.tar.gz"
  action :create_if_missing
end

directory "/opt" do
  action :create
end
execute "expand jetty" do
  command "cd /opt; tar -xzf /var/cache/chef/packages/jetty-distribution-7.1.6.v20100715.tar.gz"
  creates "/opt/jetty-distribution-7.1.6.v20100715"
  action :run
end

link "/opt/jetty-7.1" do
  to "/opt/jetty-distribution-7.1.6.v20100715"
end

remote_file "/opt/jetty-7.1/lib/jndi/amqp-client-1.8.1.jar" do
  source "http://repo1.maven.org/maven2/com/rabbitmq/amqp-client/1.8.1/amqp-client-1.8.1.jar"
  action :create_if_missing
end
remote_file "/opt/jetty-7.1/lib/jndi/commons-io-1.2.jar" do
  source "http://repo1.maven.org/maven2/commons-io/commons-io/1.2/commons-io-1.2.jar"
  action :create_if_missing
end
remote_file "/opt/jetty-7.1/lib/jndi/commons-pool-1.3.jar" do
  source "http://repo2.maven.org/maven2/commons-pool/commons-pool/1.3/commons-pool-1.3.jar"
  action :create_if_missing
end
remote_file "/opt/jetty-7.1/lib/jndi/commons-dbcp-1.2.2.jar" do
  source "http://repo1.maven.org/maven2/commons-dbcp/commons-dbcp/1.2.2/commons-dbcp-1.2.2.jar"
  action :create_if_missing
end
remote_file "/opt/jetty-7.1/lib/jndi/derby-10.4.2.0.jar" do
  source "http://repo1.maven.org/maven2/org/apache/derby/derby/10.4.2.0/derby-10.4.2.0.jar"
  action :create_if_missing
end
remote_file "/opt/jetty-7.1/lib/jndi/postgresql-8.4-701.jdbc4.jar" do
  source "http://mirrors.ibiblio.org/pub/mirrors/maven2/postgresql/postgresql/8.4-701.jdbc4/postgresql-8.4-701.jdbc4.jar"
  action :create_if_missing
end