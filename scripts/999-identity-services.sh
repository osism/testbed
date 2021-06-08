#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-infrastructure keycloak
osism-run custom keycloak-oidc-client-config
osism-run custom keycloak-ldap-federation-config
osism-kolla deploy testbed-identity
