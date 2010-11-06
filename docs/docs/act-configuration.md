---
layout: documentation
title: Documentation - Act Configuration
---
# Act Configuration #
A key part of the Circus feature set is that alongside the actual deployment of your Circus act, the system is capable of
provisioning resources and configuring your act. This allows a single act to deployed to multiple different environments,
private configuration information to be kept separate from actual application source, and for resources in the deployment
environment (such as databases) to be provisioned automatically as your application is deployed.

Configuration and provisioning information can be provided to your act via two means. Firstly, it can be added to your
`act.yaml` file. Secondly, it can be provided in a secondary configuration file, applied to the clown via the
`circus configure` mechanism.

## Configuration Format ##
As mentioned above, the configuration is provided via .yaml files. When embedded in your act.yaml file, act configuration may
look something like:

    web-app-port: 10543
    requirements:
      allocations:
      - type: Postgres
        name: mywebapp
        user: mywebapp
        password: mywebappPassword
      - type: Nginx
        target: localhost:10543
        hostname: mywebapp.example.com
        app_root: /stage/working/mywebapp/act/mywebapp/public
      - type: Nginx
        target: localhost:10543
        hostname: www.mywebapp.example.com
        app_root: /stage/working/mywebapp/act/mywebapp/public
      system-properties:
        SOME_PASSWORD: abcasdadad

The same configuration provided in an external config file might look like:

    allocations:
    - type: Postgres
      name: mywebapp
      user: mywebapp
      password: mywebappPassword
    - type: Nginx
      target: localhost:10543
      hostname: mywebapp.example.com
      app_root: /stage/working/mywebapp/act/mywebapp/public
    - type: Nginx
      target: localhost:10543
      hostname: www.mywebapp.example.com
      app_root: /stage/working/mywebapp/act/mywebapp/public
    system-properties:
      SOME_PASSWORD: abcasdadad

Note from this example that only properties specified within the `requirements` section of the act.yaml can be applied/overridden
via the external configuration file. This is due to the fact that the requirements section is processed by the Clown at deployment
time, whereas the other sections are actually utilised by the Booth during packaging - which does not support this configuration
file.

## Supported Options ##
The Clown currently supports a number of different requirement specifications. They are documented in the following sub-sections.

### System Properties ###
As mentioned above, System Properties are a useful and simple mechanism for providing environment specific data to your act. To apply
system properties, add a section such as:

    system-properties:
      SOME_PASSWORD: abcasdadad
      
to the `requirements` section of your `act.yaml`, or to the top level of your external configuration file. Properties are specified in
key/value form.

### Execution User &amp; User Profiles ###
Whilst generally not a property that should be managed in a Circus environment, some acts may require the ability to run as a specific
system user. Along with this, it may be necessary to ensure that a user account is available, and that is has a local profile available.

To require that your act's processes are run as a specific user, specify a property such as:

    execution-user: booth

in the `requirements` section of your `act.yaml`, or at the top level of your external configuration file.

If the user does not necessarily exist on the system but your application needs to run as it, then you can request that the Clown validate
(and potentially create) a user account and profile by adding the following to the `requirements` section of your `act.yaml`, or at the top level of your external configuration file:

    user-profile:
    - booth
    
### Local File Storage ###
Whilst in a "cloud" environment applications should avoid using local file storage, it is sometimes a necessity. By default, the Clown
deploys acts into a readonly sandbox. To allow an act to write to the filesystem, it should request local file storage. This can be done by adding
the following to the `requirements` section of your `act.yaml`, or at the top level of your external configuration file:

    local-file-storage:
    - BUILD_DIR
    - DATA_DIR

The values provided in the list to local-file-storage represent the names of the environment variables that will be set containing the location
of directories that have been allocated. Currently, the Clown will allocate this data directory underneath a `/stage/local_data/<actname>` tree.
Server Administrators may choose to make this a shared storage area, in order to make application data visible across multiple hosts. Note that
generally, however, it is preferable to use a cloud-aware storage system instead of the local system.
    
### Allocated Resources ###
Many applications require a database, or to be accessible via a specific web address. Circus refers to these as allocations, and the Clown is able
to provide these to an act via the use of Tamers. Currently, a standard Circus setup has two tamers: Nginx and Postgres. These allow you to 
configure http reverse proxies and databases respectively.

#### Nginx ####
As illustrated in the initial example, you request an Nginx forward by adding a list item to the `allocations` block. (Which features either
within the `requirements` block of your `act.yaml` or at the top level of an external configuration file).

    allocations:
    - type: Nginx
      target: localhost:10543
      hostname: mywebapp.example.com
      app_root: /stage/working/mywebapp/act/mywebapp/public

Working through the components of this:      

 * `type` - indicates that the Nginx tamer should be invoked. 
 * `target` - indicates where the application should be found. The port allocated by default tends to be profile specific. However, most profiles for webapps support the `web-app-port` property (shown in the original example) to allow a custom (non-conflicting) port to be allocated.
 * `hostname` - the hostname that Nginx should forward through to the application. Note that your DNS will already need to be pointing to your Nginx instance so that it is able to receive requests directed to this name.
 * `app_root` - (optional) allows you to specify static resources that should be served as part of your application. For now, you need to specify the entire path to find the file on the server. This means prefixing the act-relative path with `/stage/working/<actname>/act/<actname>`. The need to do this will be eliminated in a future release.

#### Postgres ####
As illustrated in the initial example, you request a Postgres database setup by adding a list item to the `allocations` block. (Which features either
within the `requirements` block of your `act.yaml` or at the top level of an external configuration file).

    allocations:
    - type: Postgres
      name: mywebapp
      user: mywebapp
      password: mywebappPassword
      
Working through the components of this:

 * `type` - indicates that the Postgres tamer should be invoked.
 * `name` - the name of the database that is required (and will be created if missing).
 * `user` - the user to connect with (will be created if missing).
 * `passowrd` - the password to connect with (if the user is created, their password will be set to this).

It is the intent that in future versions of Circus that not all of the database details will be required, and that the tamer will automatically
assign these values - but at this point, the management is fairly manual.
 