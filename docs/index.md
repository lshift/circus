---
layout: default
title: Welcome
---
Circus is tooling for deploying all parts of your application on one server or many servers.

<div class="info">
  <h3>Early Stage Software Warning</h3>
  <p>
    Circus is still just starting, and we're not quite there with the documentation. You may find gaps in
    the documentation - we're working on it. Do let us know via the <a href="/support.html">Support</a> mechanisms
    what you're interested in so we can get the documentation into a useful shape as quickly as possible.
  </p>
</div>


## Why Circus?
Application deployment and provisioning platforms such as <a href="http://code.google.com/appengine/">Google AppEngine</a> and <a href="http://www.heroku.com">Heroku</a> are fast becoming popular methods for deploying your applications in a trouble free and scalable manner. These platforms do have limitations however - you cannot host them on your own hardware, and you can only run the languages that they currently support.

Circus aims to provide a deployment and provisioning system that can be run on your servers, and be extended to any language/development platform.

## What makes up a Circus?
A circus deployment contains a number of different components, each responsible for managing different parts of the deployment process. At this stage, the following terms are used:
 * __Act__ - a packaged version of your application that be deployed and execute on a node;
 * __Act Store__ - a web server that provides a web accessible storage mechanism for acts;
 * __Clown__ - a management agent that runs on each deployment node. Supports the deployment and configuration of Acts;
 * __Booth__ - a packaging front-end that will checkout code from source control, package it, and send it to an Act Store;
 * __Tamers__ - adapter applications that support resource allocation on external systems. Current tamers are:
  * __Postgres__ - supports creation of databases for applications;
  * __Nginx__ - supports dynamic vhost routing;

## I still don't get it
Perhaps try looking at the <a href="/faq.html">FAQ</a>?

## Sold. How do I get started?
To begin deploying with Circus, you'll need to configure at least one deployment node, and install the management tools. To setup a test environment and learn how to use Circus, take the <a href="/docs/fast-track">Fast Track</a>.
