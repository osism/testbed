#!/usr/bin/env bash
set -e

export INTERACTIVE=false

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

osism apply common
osism apply loadbalancer

osism apply openstackclient
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply openvswitch

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ || $OPENSTACK_VERSION == "yoga" ]]; then
    osism apply elasticsearch
    if [[ "$REFSTACK" == "false" ]]; then
        osism apply kibana
    fi
else
    osism apply opensearch
fi

if [[ "$REFSTACK" == "false" ]]; then
    osism apply homer
    osism apply phpmyadmin
fi

osism apply ovn

if [[ "$REFSTACK" == "false" ]]; then
    # NOTE: Run a backup of the database to test the backup function
    osism apply mariadb_backup
fi

osism apply keycloak
osism apply --environment custom keycloak-oidc-client-config
