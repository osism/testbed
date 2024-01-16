#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

osism apply loadbalancer-ng

osism apply --no-wait common
osism apply --no-wait openstackclient
osism apply --no-wait memcached
osism apply --no-wait redis
osism apply --no-wait rabbitmq
osism apply --no-wait openvswitch

osism wait

osism apply --no-wait mariadb
osism apply --no-wait ovn

osism wait

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ || $OPENSTACK_VERSION == "yoga" ]]; then
    osism apply elasticsearch
    if [[ "$REFSTACK" == "false" ]]; then
        osism apply kibana
    fi
else
    osism apply opensearch
fi

if [[ "$REFSTACK" == "false" ]]; then
    # NOTE: Run a backup of the database to test the backup function
    osism apply mariadb_backup
fi

osism apply keycloak
osism apply --environment custom keycloak-oidc-client-config
