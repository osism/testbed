#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-infrastructure keycloak
osism-run custom keycloak-oidc-client-config
osism-kolla deploy testbed-identity
