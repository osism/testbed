#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply common
osism apply loadbalancer
osism apply elasticsearch
osism apply kibana
osism apply memcached
osism apply redis
osism apply rabbitmq

osism apply openstackclient
osism apply homer
osism apply phpmyadmin

osism apply openvswitch
osism apply ovn

osism apply keycloak
osism apply --environment custom keycloak-oidc-client-config

osism apply mariadb
# NOTE: Run a backup of the database to test the backup function
osism apply mariadb_backup
