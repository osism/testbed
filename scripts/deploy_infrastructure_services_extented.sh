#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-generic osquery
osism-generic cockpit

osism-infrastructure patchman
osism-generic patchman-client
osism-run custom bootstrap-patchman
