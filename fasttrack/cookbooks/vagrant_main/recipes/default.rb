# Circus Repository
require_recipe 'circus_repo'

# Support for Ruby on nodes (for both Circus internal and user apps)
require_recipe 'ruby'

# Support for Python on nodes
require_recipe 'python'

# Support for booths
require_recipe 'booth_support'

# Support for webapps
require_recipe 'nginx'

# Support for being a postgres server
require_recipe 'postgresql::server'

# Support for hosting static resources
require_recipe 'lighttpd'

# Support for building Jekyll sites
require_recipe 'jekyll'

# Install the Clown
require_recipe 'clown'
