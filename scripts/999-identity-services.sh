#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-infrastructure keycloak
osism-kolla deploy testbed-identity
