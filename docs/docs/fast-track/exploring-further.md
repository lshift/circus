---
layout: fast_track
title: Fast Track - Exploring Further
---
# Exploring Further #
There is plenty more to explore within Circus. This page aims to give you a taster, but we'd highly recommend having a look at the following pages:
 
 * The <a href="/docs/management.html">Management</a> documentation details everything the Circus command line tool can make your infrastructure do.
 * The <a href="/docs/act-configuration.html">Act Configuration</a> documentation details how you can customise your acts in different environments.
 * The <a href="/docs/security.html">Security</a> documentation explains how your Circus installation is kept secure.
 * The <a href="/docs/architecture.html">Architecture</a> documentations goes into how Circus is actually achieving what is does.

## Taster ##

Executing remote commands:
{% highlight bash %}
$ circus exec ssh://vagrant@192.168.11.10 myfirstapp ls
act.yaml	config.ru
{% endhighlight %}

Undeploying your application:
{% highlight bash %}
$ circus undeploy ssh://vagrant@192.168.11.10 myfirstapp
...
{% endhighlight %}