---
layout: documentation
title: Documentation - Architecture
---
# Architecture
As with the intended design of applications that can be deployed with Circus, the actual infrastructure running deployment consists of a number of components interacting with each other to achieve the necessary operations. 

Initially, this page aims to explain the various components involved in deployment, and how they interact with each other. From there, it moves onto describing how these components work internally. Whilst it shouldn't be necessary to understand all of the details in order to use Circus, it is hopefully likely to make the deployment process seem far less of a black box.

## The Deployment Process
In the most basic deployments, the following components are necessary to achieve the transfer of an application from a developer's local machine to a hosted state on a node:

 * Booth
 * SCM (Source Repository)
 * Act Store
 * Clown
 
The following diagram illustrates the interaction of these components when a deployment is initiated by a user:

<img class="" src="/images/deployment_sequence.png">

Following this process through, the following series of events occur:

 1. The user issues a request via their management tools to initiate a deployment for an application.
 2. The request is sent to the Booth, which checks out or updates the code from the source repository.
 3. The booth then packages the code into an act file (or series of act files if the application defines a number of them).
 4. The produced act file(s) are then uploaded to the act store, and the booth returns details of them to the initiating
    management tool.
 5. The management tool requests that a Clown deploy the given acts.
 6. The Clown downloads the act from the store, and performs the necessary processes to mount, prepare and run it.
 7. Deployment results are provided to the management tool.
 
## Building an Act with the Booth
The overall aim of the booth is to take a raw source application, and transform it into a generic pre-prepared code bundle that can be installed and executed by a Clown with a minimum of effort. In order to achieve this, the Booth packages acts using the SquashFS filesystem, and produces standard artefacts in the root of the package describing to the clown the "last-mile" activities that need to be performed to make the application functional.

As explained later in the Clown documentation, a mounted Act is managed via daemontools. This means that the entry-point to the application should be via a shell script named `run` that will be executed with no arguments.

Given this simple entry-point API, the Booth is built with a series of "profiles" that will recognise a specific type of application (eg, Ruby Rack web application, Django application, shell application) and perform the necessary transformations to result in a bundle that can be successfully booted through the execution of the `run` script.

Since many applications require additional resources to run or be useful (databases, inbound http requests), an act can also contain a resource descriptor file (named `resources.yaml`) that describes any additional resources that the Clown must make available to the act in order for it to execute successfully. The content of this file is generated through a combination of output from the profile, and stanzas provided directly by application configuration files.

## Deploying an Act with a Clown
Once the booth has packaged the act into a SquashFS filesystem and made it available via the Act Store, the Clown can be instructed to deploy it. The broad process that a Clown follows to activate an act are:

 1. Download the act from the act store in the stage image directory (generally /stage/images).
 2. Performs first stage preparation of the working directory (generally /stage/working/&lt;appname&gt;). This consists of
    generating mount scripts that automate the mounting of the act via a loopback filesystem.
 3. Execution of the mount scripts to make the act content available within the working directory.
 4. Processing (and fulfilling) any resource requests specified in the `resources.yaml` and generating a `with_env` script
    that can be used to execute processes within the environment prepared for the act (for example, changing to the correct
    directory, setting environment variables and changing the execution user).
 5. Generate a top-level `run` script that executes the booth generated `run` script via the `with_env` script (essentially, 
    executing the `run` script the booth generated within the context of the resources it requested).
 6. Symlink the working directory into the directory managed by daemontools `svscan` service (generally, /etc/service).
 7. Waiting for daemontools to start the act.

### Acquiring resources
Given a key value proposition of Circus is the resource acquisition mechanism, the techniques used for acquiring resources deserves special attention.

TODO
