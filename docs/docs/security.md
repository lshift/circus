---
layout: documentation
title: Documentation - Security
---
# Security #
Circus relies on the security of its underlying components to prevent invalid or unauthorized actions from being performed. This allows
for standard administration techniques to be employed, instead of requiring a completely new administrative technique.

## Clown Security ##
Clowns are communicated with via SSH and D-Bus. Connectivity to the actual host machine is managed via SSH public-key authentication,
a very standard technique for password-less access to hosts. Once connected to the host, commands are issued to the Clown via
D-Bus, which utilises local user privileges to restrict access. Users are required to be a member of the "admin" group in order to
speak to the Clown - membership of this group can be managed via standard UNIX group primitives, or even via central directories if
hosts are configured in this manner.

## Booth Security ##
Similarly to the security of the Clown, the Booth is accessed via SSH and D-Bus.

## Act Store Security ##
At this stage, the Act Store does not provide any security mechanisms for preventing uploads or access. Firewalling techniques can
be used to restrict access if necessary. Note that the Act Store is a very simple RESTful store, and it would be possible to replace
this with a more tightly configured HTTP daemon if necessary.