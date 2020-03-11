#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure helper --tags openstackclient
osism-infrastructure netdata
osism-generic cockpit

osism-kolla deploy --tags infrastructure
