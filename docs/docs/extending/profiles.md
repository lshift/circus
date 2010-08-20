---
layout: documentation
title: Documentation - Extending - Application Profiles
---
# Adding an application profile
Circus already comes with support for various application type such as Ruby and Python, and it is easy to add your own. The following is a walkthrough on the Jekyll profile ([Jekyll](http://github.com/mojombo/jekyll) is a static site generator that is used to publish the Circus documentation).

## Add the profile class
The class is in the file `circus/lib/profiles/jekyll.rb`. Below is a description of the key elements.

{% highlight ruby %}
require File.expand_path('../base', __FILE__)

module Circus
  module Profiles
    class Jekyll < Base
...
{% endhighlight %}

The class must descend from the `Circus::Profiles::Base` class. There are also helper classes that provide default behaviour to adapt, e.g., `ruby_base.rb` or `python_base.rb`.

{% highlight ruby %}
def self.accepts?(name, dir, props)
  return File.exists?(File.join(dir, "_config.yml"))
end
{% endhighlight %}

Circus needs to know the profile to use when building an Act, and it does this by apply the `accepts?` test on each profile in turn. You can put anything in here as long as it is sufficient to determine the profile type. In this case, Circus will look for a Jekyll `_config.yml` file. The `pure_rb.rb` file demonstrates how to use a property to explicity guide this choice.

{% highlight ruby %}
def name
  "jekyll"
end
{% endhighlight %}

Make sure you define a name for your profile for logging purposes.

{% highlight ruby %}
def package_base_dir?
  false
end
      
def extra_dirs
  ["#{@dir}/_site"]
end
{% endhighlight %}

You can control what is packaged by overriding the `package_base_dir?` and `extra_dirs` methods. In this case, we only package the `_site` directory which is where the Jekyll generator will output the static HTML.

{% highlight ruby %}
def prepare_for_dev(logger, run_dir)
end

def prepare_for_deploy(logger, overlay_dir)
  run_external(logger, 'Generate site with Jekyll', "cd #{@dir}; jekyll")

  # Create lighttpd.conf
  File.open(File.join(overlay_dir, 'lighttpd.conf'), 'w') do |f|
    f.write <<-EOT
      server.document-root = "_site/" 

      server.port = env.HTTPD_PORT

      ...

    EOT
  end
  true
end

def cleanup_after_deploy(logger, overlay_dir)
  run_external(logger, 'Clean generated site', "cd #{@dir}; rm -r _site")
end
{% endhighlight %}

Circus has two ways of preparing an application:
 * an unpacked version of the Act is created and executed locally using `circus go` during development
 * an Act bundle is created using `circus assemble` for subsequent deployment

Often these two targets are the same and in this case, you would call one of the preparation methods above from the other. For Jekyll, we want to use the server that comes with it for development as it will incrementally build the site as we make changes. For deployment, we use [lighttpd](http://www.lighttpd.net/).

The `prepare_for_dev` method does nothing (and is included here only for illustration) as the Jekyll server works over the source files and no preparation is required.

The `prepare_for_deploy` method has two stages. Firstly it calls Jekyll using the `run_external` method to generate the static site. It then writes out the `lighttpd.conf` file to the overlay directory.

{% highlight ruby %}
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
{% endhighlight %}

Circus uses [daemontools](http://cr.yp.to/daemontools.html) to execute Acts which means there must be a `run` script. The `dev_run_script_content` and `deploy_run_script_content` methods are used to insert the actual execution statement into this file. 

## Registering the Profile
To make the profile available, it should be added to the constant list `Circus::Profiles::PROFILES`:
{% highlight ruby %}
  PROFILES << Jekyll
{% endhighlight %}


The Jekyll code should also be loaded with the other profiles by adding a `require` statement to the file `circus/lib/circus/profiles.rb`:
{% highlight ruby %}
require File.expand_path('../profiles/jekyll', __FILE__)
{% endhighlight %}

## Add tests
There is an RSpec test definition for the Jekyll profile in the file `circus/spec/profiles/jekyll_spec.rb`.