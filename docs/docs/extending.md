---
layout: documentation
title: Documentation - Developing/Extending Circus
---
# Developing/Extending Circus
If you'd like to extend Circus, the first thing you'll need is a development environment capable of building the various Circus components. After that, you'll be able to make changes to any part of the Circus infrastructure - for example, you could add new packaging mechanisms, introduce more resources that can be allocated or add another tamer to manage another external service

## Getting the source
The source for Circus is available from GitHub.

{% highlight bash %}
$ git clone git://github.com/paulj/circus
{% endhighlight %}

## Setup Dependencies
The Circus build environment relies heavily on <a href="http://vagrantup.com">Vagrant</a> to provide reproducible Virtual Machines in a simple, automated manner. Briefly, to get Vagrant working:
 * Ensure that you have a working VirtualBox 3.2.x (non-OSE) install (at the time of writing, version 3.2.6 was known to work well)
 * Install Vagrant and download the necessary base boxes:
  {% highlight bash %}
  $ sudo gem install vagrant
  $ vagrant box add lucid32v2 http://s3.lds.li/vagrant/lucid32v2.box
  $ vagrant box add lucid64v2 http://s3.lds.li/vagrant/lucid64v2.box
  {% endhighlight %}

You'll also want to install the development dependencies via the <a href="http://gembundler.com">Ruby Gem Bundler</a>:
{% highlight bash %}
$ cd circus
$ bundle install
{% endhighlight %}

## Initialising the packaging environment
The Circus build uses two Vagrant VMs for packaging. A 32-bit Ubuntu 10.04 VM, and a 64-bit Ubuntu 10.04 VM. These VMs will be automatically used when the packaging tasks are executed in the Rakefile, so to configure everything, just run the following in the root of your circus checkout:

{% highlight bash %}
$ rake packaging:all
{% endhighlight %}

Once this process is completed, you should have a packages/ directory, with contents similar to:
{% highlight bash %}
$ find packages -type f
packages/acts/actstore-i386.act
packages/acts/booth-x64.act
packages/acts/postgres-x64.act
packages/acts/booth-i386.act
packages/acts/actstore-x64.act
packages/acts/nginx-x64.act
packages/acts/postgres-i386.act
packages/acts/nginx-i386.act
packages/debs/clown_0.1-1_i386.changes
packages/debs/clown_0.1-1_all.deb
packages/debs/Packages.gz
{% endhighlight %}

## Building a test node
Alongside the packaging VMs, the Circus build environment also defines a node VM that can be used to test the various components built as part of circus. All components can be deployed to it automatically by running:

{% highlight bash %}
$ rake deployment:all
{% endhighlight %}
