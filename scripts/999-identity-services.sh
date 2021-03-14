#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-kolla deploy testbed-identity
