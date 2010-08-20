# Development installs of the Clown
require_recipe 'dev'
require_recipe 'clown'

# Support for booths
require_recipe 'booth_support'

# Support for webapps
require_recipe 'nginx'

# Support for Python on nodes
require_recipe 'python'

# Support for being a postgres server
require_recipe 'postgresql::server'
