#!/usr/bin/env bash

export INTERACTIVE=false

osism apply openstackclient
osism apply keycloak
osism apply openldap

osism-run custom openldap-umc-policies
osism-run custom umc-admin-ldap
osism-run custom keycloak-oidc-client-config
osism-run custom keycloak-ldap-federation-config

osism apply common
osism apply haproxy
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon
