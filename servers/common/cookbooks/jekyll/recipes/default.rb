gem_package 'jekyll' do
  version '0.6.2'
  action :install
  gem_binary "/usr/bin/gem"
end
package 'python-pygments'
