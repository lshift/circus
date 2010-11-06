---
layout: documentation
title: Documentation - Management
---
# Management

Management of Circus applications is done via the Circus CLI tool. At any point, you can list the commands that it supports
by executing:
{% highlight bash %}
$ circus help
Tasks:
  circus admit [NAME] [ACT1 ACT2]             # Admits and deploys the application with the given booth reference
  circus alias NAME TARGET                    # Adds an alias so that NAME can be used when target TARGET is desired
  circus assemble                             # Assemble the application's acts for deployment
  circus configure TARGET NAME CONFIG         # (Re)configures the given act on the given target using the provided config details
  circus connect NAME BOOTH                   # Associates the local application with the provided booth to allow for deployment
  circus deploy TARGET NAME ACT               # Deploy the named object using the given act onto the given target server
  circus exec TARGET [ACT] [CMD]              # Executes the given command in the deployed context of the given act
  circus get-booth-key BOOTH                  # Retrieves the public key that a booth will use when connecting to SSH resources
  circus go                                   # Run the current application in place for development
  circus help [TASK]                          # Describe available tasks or one specific task
  circus pause ACT_NAME                       # Temporarily halts an act that is running in development (via go)
  circus reset TARGET ACT                     # Restarts the given act on the target host
  circus resume ACT_NAME                      # Resumes a paused act that is running in development (via go)
  circus undeploy TARGET NAME                 # Undeploys the named act from the given target server
  circus upload FILENAME --actstore=ACTSTORE  # Uploads the given set of act files to act store

Options:
  [--source=SOURCE]  # Source directory containing the application
                     # Default: .
{% endhighlight %}

As can be seen, this utility supports a substantial number of commands. Individual commands (and their specific options) can
be explored via: {% highlight bash %}circus help [task]{% endhighlight %}

The following sections provide a categorised overview of the commands provided, and situations in which you might want to use
them.

## Application Deployment with a Booth
A number of primitives are provided for the actual deployment of your application via the booth component. The Booth provides
an easy mechanism for getting from a raw source repository to a deployed application, using a controlled server to build your
application.

### Keying a Booth ###
For many Version Control Systems (Git, Mercurial), a common method of securing the repository is via SSH keys. Since the Booth
checks out your application's code on the server, it will require access to your repository. In scenarios where anonymous access
isn't available, the booth provides mechanisms for generating an SSH key which you can provide access to.

To retrieve the key for the booth (which it will generate on first use), execute:

{% highlight bash %}
$ circus get-booth-key ssh://myboothserver
SSH key for: ssh://myboothserver
  ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxHxZEuK8HLhvF5dS+na5cIequmUTnRYEkhdas87adadbadCNDQ0U1V93LlydoPPbKni
j/MqvoR+jd7VTI32oJsq+zeoIrdGDxwlhENmzDWZ3eoipd8zqjymJ36JRIVVRuzduIffur4NvzY/ajkzhsGzbiY5vKQFVZ5X7seXI8NF/FVYtFHT0vZfyFkyGVWN
dsaakdja/dad79asdpeDgp9+wQgJG83THyfiMmyv5hT3GA/Bg1xrwgbXKkIhcsXRh48KPFIX2sRMYPd4g7pNNRlh+6DQG3LU+EEPXx82x1nnNaYiIxBsk6v/asda
da7d9797== booth@myboothserver
{% endhighlight %}

### Configuring a booth to deploy an app ###
In order to have a booth deploy your application, you'll need to connect it to your local application checkout. This, in its
most simple form is achieved with:
{% highlight bash %}
$ circus connect prod ssh://myboothserver
{% endhighlight %}

This command instructs the circus client to setup a connection to a booth (that you it will now refer to as "prod") that is being
run on myboothserver. The circus tool will automatically detect the Version Control System being used for your app, and 
request that the booth setupa similar checkout. The tool will also set the deployment target to be myboothserver as well. 
Note that in order for this command to work, you'll need to have your SSH key authorised with the server, and be a member of the 
admin group. See the <a href="/docs/security.html">security documentation</a> for a more detailed description on this topic.

If you need the booth to checkout the code from an alternate location, or if the client fails to detect your setup, you can manually
provide details of your VCS and checkout urls. For instance, if you wanted to deploy via a public github URL instead of your private
ssh variant, you could issue a connect in manners such as:

{% highlight bash %}
$ circus connect prod ssh://myboothserver --repo-url git://github.com/lshift/circus.git
$ circus connect prod ssh://myboothserver --repo-type git --repo-url git://github.com/lshift/circus.git
{% endhighlight %}

As indicated above, the tool also defaults to running the deployment on the same host as the booth. If you wish to deploy to an alternate
host, you'll need to provide the --deploy-target option. For example:
{% highlight bash %}
$ circus connect prod ssh://myboothserver --deploy-target ssh://mydeployserver
{% endhighlight %}

As a final note, the configuration of a booth connection can be updated at any time by simply re-executing the connect command with the
same booth name. The configuration will simply be overwritten.


### Requesting the booth to deploy a connected application ###
Once a connect command has been successfully issued, an application can be deployed by executing:

{% highlight bash %}
$ circus admit
{% endhighlight %}

This will package and deploy all acts referenced from the current working copy using the current connected booth. Note that this command
will fail if you have more than one booth connected - in that case, you'll need to specify the name of the booth connection to use, such as:
{% highlight bash %}
$ circus admit prod
{% endhighlight %}

In the case where you only want to admit a specific act, you can list the acts that you want admitted. For example:
{% highlight bash %}
$ circus admit prod myfirstact mysecondact
{% endhighlight %}

Finally, whilst you're experimenting with Circus, you may find it a bit painful to keep committing every time you need to adjust a minor setting.
To make this a bit easier, the admit command accepts an "--uncommitted" argument, which allows for a local patch to be generated and uploaded
to the booth to be applied before packaging. Whilst this should be considered dangerous in a production environment, it can often accelerate
circus integration in development.
{% highlight bash %}
$ circus admit --uncommitted
{% endhighlight %}

{% highlight bash %}
{% endhighlight %}

## Manual Application Deployment ##
In some scenarios, you'll already have a packaged act available, and wish to deploy it onto your circus infrastructure. The Circus command line
tool provides a series of commands for doing this.

### Uploading an Act to your Act Store ###
If the act isn't already available at a HTTP url, you can upload it to your locally deployed actstore. This is achieved via the upload command:
{% highlight bash %}
$ circus upload /path/to/localfile.act --actstore http://myactserver:9088/acts
INFO: Uploading to http://myactserver:9088/acts/localfile.act
{% endhighlight %}

This command can also be used to upload configuration files to the actstore - see the Act Configuration section for details:
{% highlight bash %}
$ circus upload /path/to/actconfig.yaml --actstore http://myactserver:9088/acts
INFO: Uploading to http://myactserver:9088/acts/actconfig.yaml
{% endhighlight %}

### Deploying an Act from an Act Store ###
Once an act is available from an act store, you can instruct a Clown to deploy it. This is achieved via the deploy command:
{% highlight bash %}
$ circus deploy ssh://mydeployhost myact http://myactserver:9088/acts/myact.act
INFO: Executing deployment of myact from http://myactserver:9088/acts/myact.act to ssh://mydeployhost
INFO: Executing package deploy of: myact
...
{% endhighlight %}

Note that you can also deploy from the *Clown's* local filesystem by specifying a file path to the deploy command. This is often
very useful for bootstrapping deployments:
{% highlight bash %}
$ circus deploy ssh://mydeployhost myact /tmp/myact.act
INFO: Executing deployment of myact from /tmp/myact.act to ssh://mydeployhost
INFO: Executing package deploy of: myact
...
{% endhighlight %}

### Undeploying an Act ###
Whenever an act is deployed, any previous versions with the same name with be automatically removed. However, if you wish to undeploy
an act outside of this, the undeploy command can be used:

{% highlight bash %}
$ circus undeploy ssh://mydeployhost myact
...
{% endhighlight %}

Note that currently undeployment will remove all application files, but will not cleanup any allocated resources. 

## Application Management ##
Once an application is successfully able to be deployed and undeployed, the Circus tools provide some additional management options
to further simplify application development.

### Restarting a deployed application ###
Whilst Circus aims to provide a managed fabric for the applications, it occasionally proves necessary to manually interrupt them. To force
an application to restart, the reset command can be used:

{% highlight bash %}
$ circus reset ssh://mydeployhost myact
...
{% endhighlight %}

This command will shutdown and then restart the given application. No deployment actions will be taken - this action simply restarts the 
associated processes.

### Executing Commands in the Deployed Environment ###
To allow for application specific administration commands (eg, setting up and seeding databases, diagnostics), Circus provides the ability
to remote execute commands in the environment that the application is executing in. For example, if you've deployed a Rails application and
need to migrate the database, you could execute:

{% highlight bash %}
$ circus exec ssh://mydeployhost myrailsapp rake db:migrate
INFO: Act myrailsapp executing rake db:migrate
...
{% endhighlight %}

## Application Configuration ##
Part of the Circus philosophy is that the one act should be deployable into multiple environments, and that environment specific configuration
(keys, urls, databases) can be read in externally from the environment. In order to achieve this, the Clown supports being instructed of a
secondary configuration file to "mix" with the act whilst it is deploying it. The configuration file can specify additional resources to
be setup (eg, databases, environment properties). The format and contents of these configuration files are specified on the
<a href="/docs/act-configuration.html">Act Configuration</a> page.

As detailed in the Uploading section, configuration can be uploaded to an act store with:
{% highlight bash %}
$ circus upload /path/to/actconfig.yaml --actstore http://myactserver:9088/acts
INFO: Uploading to http://myactserver:9088/acts/actconfig.yaml
{% endhighlight %}

To apply this configuration, the "configure" command can be issued:
{% highlight bash %}
$ circus configure ssh://mydeployhost myact http://myactserver:9088/acts/actconfig.yaml
...
{% endhighlight %}

Configuration will be retained across subsequent redeploys too, so the configure command does not need to be re-executed.

## Local Development ##
To simplify the process of developing multi-act applications locally, the Circus command line tool provides partial-support for simulating
the deployed environment. Mostly, this involves allowing the various profiles an act can take on to run the act in a "development" mode appropriate
for the application type.

To start all of your acts on your local machine, execute:
{% highlight bash %}
$ circus go
{% endhighlight %}

This will package all of your acts for development, then use daemontools to start the act. Note that the daemontools svscan utility will need
to be available on your command line for this to work (so unfortunately, at this point this will mainly only work for Linux and OS X users).

Whilst running in this mode, individual acts can be paused and resumed via:
{% highlight bash %}
$ circus pause myact
$ circus resume myact
{% endhighlight %}

This is frequently useful when you need to bring up one act from your set in a more controlled manner - perhaps under a debugger - but don't want
to have to run everything manually.