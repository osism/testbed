#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply common
osism apply loadbalancer

osism apply keycloak
osism apply openstackclient
osism apply elasticsearch
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply openvswitch

if [[ "$REFSTACK" == "false" ]]; then
    osism apply homer
    osism apply kibana
    osism apply phpmyadmin
fi

osism apply ovn
osism apply --environment custom keycloak-oidc-client-config

if [[ "$REFSTACK" == "false" ]]; then
    # NOTE: Run a backup of the database to test the backup function
    osism apply mariadb_backup
fi
