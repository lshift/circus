---
layout: fast_track
title: Fast Track - What is Circus?
---
# What is Circus?

 * Circus is a framework for packaging, deploying and provisioning applications
 * Circus simplifies application deployment across a cluster
 * Circus makes it easier to define applications in terms of interacting components
 * Circus facilitates automated integration testing
 * Circus is language / framework agnostic

Circus is not:

 * a replacement for Puppet or Chef

Circus consists of:
 * Acts; an Act is a single application, packaged for easy deployment
 * Nodes; the machines that will run the application
 * Clowns; Clowns manage the deployment and execution of Acts on Nodes
 * a Booth; a front-end that will controls the packaging and publishing of Acts
 * an Act Store; web accessible storage for Acts
 * Tamers; adapter applications that can allocate resources on Nodes

Circus is written in Ruby and builds on:
 * DaemonTools
 * Vagrant
 * VirtualBox
 * Squashfs

Circus current supports the following application types:
 * pure Ruby
 * Ruby Rack
 * pure Python 
 * Django
 * Shell

Type support is provided by adaptors so this list will be added to.

## Overview of a Circus deployment
A deployer makes a request to deploy a Circus application using the Circus client. The Booth check outs the relevant version of the application from a SCM system, converts it into an Act and then publishes it to the Act Store. The Circus client then makes a deploy request to the Clowns. These download the Act from the Act Store and executes them.

__Next__ --> <a href="/docs/fast-track/download-install.html">Downloading and Installing Circus</a>
