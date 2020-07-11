#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure openstackclient
osism-generic osquery
osism-generic cockpit

osism-infrastructure patchman
osism-generic patchman-client
osism-run custom bootstrap-patchman

osism-kolla deploy testbed --tags infrastructure
