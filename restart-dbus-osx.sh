#!/bin/sh

mkdir -p /var/run/dbus
launchctl stop org.freedesktop.dbus-system
rm /opt/local/var/run/dbus/pid
launchctl start org.freedesktop.dbus-system
