#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure openstackclient
osism-infrastructure keycloak
osism-infrastructure openldap
osism-run custom openldap-umc-policies
osism-run custom umc-admin-ldap
osism-run custom keycloak-oidc-client-config
osism-run custom keycloak-ldap-federation-config
osism-kolla deploy testbed-identity
