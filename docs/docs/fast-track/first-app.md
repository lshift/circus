---
layout: fast_track
title: Fast Track - Deploying your first application
---
# Deploying your first application
Our first Circus deployed application is going to be written in Ruby. Please do be aware that Circus is capable of much more than just Ruby, but seeing as much of Circus already runs in Ruby, we've got all the dependencies installed already - so it makes it nice and easy to get going. The aim will be to write a very simple web application that shows a hello world page - obviously very cliched, but nonetheless still a useful starting point.

Circus also requires a source repository shared between both your machine and the deployment node running the booth. Since setting up a source control server is far beyond the scope of this tutorial, we're going to cheat and use `git daemon` running out of a local repository. You'll need a fairly recent version of git for this (1.5.6.5 doesn't work, 1.7.1 does, YMMV with versions inbetween)

## Setting up your Git "Server"
As mentioned above, we're going to use git daemon to run a local git server. To do this, we'll create a repository for the server to work off, then run git daemon in it.

{% highlight bash %}
$ mkdir -p tmp/repos
$ cd tmp/repos
$ git init --bare myfirstapp
$ git daemon --reuseaddr --base-path=. --export-all --verbose  --enable=receive-pack
{% endhighlight %}

Note that the final command (`git daemon`) will just sit there appearing to have hung. It hasn't - it is waiting for connections. We're now ready to start working against it.

## Writing your application
In another window/terminal, clone the repository:
{% highlight bash %}
$ git clone git://192.168.11.1/myfirstapp
...
warning: You appear to have cloned an empty repository.
$ cd myfirstapp
{% endhighlight %}

A few things to note here:

 * The IP 192.168.11.1 was allocated during the install of your node. Your deployment node will be listening on 192.168.11.10.
 * The git clone emits a warning. It can be safely ignored.

Now we've got a working directory for our application, lets write it. We're going to use <a href="http://www.sinatrarb.com/">Sinatra</a>, so we need a few dependencies first:
{% highlight bash %}
$ sudo gem install thin
$ sudo gem install sinatra -v 1.0
{% endhighlight %} 

and then some files:

__config.ru__
{% highlight ruby %}
require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'

get '/' do
  "Hello World"
end

run Sinatra::Application
{% endhighlight %} 

__Gemfile__
{% highlight ruby %}
source :rubygems
gem 'sinatra', '1.0'
gem 'thin'
{% endhighlight %}

There are two parts to this application. The config.ru (a standard <a href="http://rack.rubyforge.org">Rack</a> entry point) that defines a handler for the url /. The Gemfile describes the dependencies for your application.

To test your application, run:
{% highlight bash %}
$ thin -R config.ru start
>> Thin web server
>> Maximum connections set to 1024
>> Listening on 0.0.0.0:3000, CTRL+C to stop
{% endhighlight %}

Browse to <a href="http://localhost:3000">http://localhost:3000</a>, and you'll see your application. 

Since we're done writing our application, we should commit it:
{% highlight bash %}
$ git add config.ru Gemfile
$ git commit -m "My new application"
$ git push origin master
{% endhighlight %}

## Deploying your application
Now we've written our app, we'd like to deploy it onto our deployment node. To do this, we need to associate our local working copy with a Circus booth, then request that the booth admit (build and deploy) our application.

To associate our application:
{% highlight bash %}
$ circus connect staging ssh://vagrant@192.168.11.10
{% endhighlight %}

This will open an SSH connection as the vagrant user (included in the base OS image), connect to the Booth, and request that it connect to this repository. The booth will return details of the connection to your local client, which are cached in the `.circus` directory.

Now to deploy our application:
{% highlight bash %}
$ circus admit
{% endhighlight %}

To see the deployed results of your efforts, browse to <a href="http://192.168.11.10:3000">http://192.168.11.10:3000</a>. Your first Circus deployment is complete!

Now that you've mastered the (bare) basics, we can move onto far more interesting topics.

__Next__ --> <a href="/docs/fast-track/exploring-further.html">Exploring Further</a>