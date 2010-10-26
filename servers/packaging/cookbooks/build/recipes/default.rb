execute "apt update" do
  command "apt-get update"
end

package 'build-essential'
package 'cdbs'
package 'debhelper'
package "ruby"
package "ruby-dev"
package "rubygems"
package "libxml2"
package "libxml2-dev"
package "libxslt1-dev"
package "libssl-dev"
package "reprepro"

package 'squashfs-tools'

gem_package 'rake'
gem_package 'rspec' do
	version '1.3.0'
end
