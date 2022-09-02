#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply openstackclient
osism apply keycloak
osism apply --environment custom keycloak-oidc-client-config
osism apply common
osism apply loadbalancer
osism apply elasticsearch
osism apply openvswitch
osism apply memcached
osism apply redis
osism apply mariadb
osism apply kibana
osism apply ovn
osism apply rabbitmq
osism apply homer

# NOTE: Run a backup of the database to test the backup function
osism apply mariadb_backup

osism apply phpmyadmin
