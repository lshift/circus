---
layout: fast_track
title: Fast Track - Downloading and Installing
---
# Downloading and Installing Circus
To begin using Circus, you'll need a Circus Deployment node (to run your applications) and management tools to control the deployment. Binaries of the latest released Circus version are made available, and this page will walk you through their installation. If you'd like to work on the very bleeding edge, then refer to the <a href="/docs/extending.html">Development Install</a> page.

## Getting the installation helpers
The Circus codebase includes some useful helpers for performing installation, so the first stop is to retrieve those. Clone them from github with:

{% highlight bash %}
$ git clone git://github.com/lshift/circus
{% endhighlight %}

Within your circus directory, you should find a directory called `fasttrack` - this contains the various tools that help with installation.

## Installing management tools
Before we can build any nodes, you'll need the management tools available. The management tools support installing and removing acts from your nodes, along with numerous other useful commands that we'll see later.

Install the current release of the management tools via Rubygems:

{% highlight bash %}
$ sudo gem install circus-deployment
{% endhighlight %}

## Installing a Deployment Node
To run your deployment node, you'll need <a href="http://www.vagrantup.com">Vagrant</a>. Vagrant is a wrapper around <a href="http://www.virtualbox.org/">Oracle VirtualBox</a> providing the ability to define reproducible Virtual Machine instances. Installing your deployment node into a Virtual image instead of directly onto your machine eliminates the need for specific dependencies/operating system installs in order to experiment with Circus.

So, before you can proceed, you'll need a working Vagrant/VirtualBox install. This consists of:

 * Ensure that you have a working VirtualBox 3.2.x (non-OSE) install (at the time of writing, version 3.2.6 was known to work well)
 * Install Vagrant and download the necessary base boxes:
 {% highlight bash %}
 $ sudo gem install vagrant
 $ vagrant box add lucid32v2 http://s3.lds.li/vagrant/lucid32v2.box
 {% endhighlight %}

Now that Virtual Machines can be created, change into the `fasttrack` directory of your circus checkout, and execute:
{% highlight bash %}
$ rake node:build
{% endhighlight %}

At the completion of this, you'll end up with a Circus deployment node running the following:

 * A __Clown__ -- the management agent for installing and activating acts
 * An __Act Store__ -- allowing you to upload your own acts for deployment
 * A __Booth__ -- for packaging your applications into acts
 * A __Postgres Tamer__ -- providing automated database provisioning
 * A __Nginx Tamer__ -- providing automated providing of web front ends

We're now ready to deploy an application!

__Next__ --> <a href="/docs/fast-track/first-app.html">Deploying your first application</a>

