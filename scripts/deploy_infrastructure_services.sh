#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure openstackclient
osism-generic cockpit

osism-kolla deploy testbed --tags infrastructure
