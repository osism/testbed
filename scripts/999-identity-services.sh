#!/usr/bin/env bash

export INTERACTIVE=false

osism apply openstackclient
osism apply keycloak
osism apply openldap

osism apply --environment custom openldap-umc-policies
osism apply --environment custom umc-admin-ldap
osism apply --environment custom keycloak-oidc-client-config
osism apply --environment custom keycloak-ldap-federation-config

osism apply common
osism apply haproxy
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon
