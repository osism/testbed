#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure openstackclient
osism-infrastructure patchman
osism-generic osquery
osism-generic patchman-client
osism-generic cockpit

osism-kolla deploy testbed --tags infrastructure
