#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply openstackclient
osism apply keycloak

osism apply --environment custom keycloak-oidc-client-config

osism apply common
osism apply loadbalancer
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon

osism apply --environment openstack bootstrap-keystone
osism apply homer
