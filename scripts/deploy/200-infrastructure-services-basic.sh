#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply common
osism apply loadbalancer

task_ids=$(osism apply --no-wait --format script openstackclient 2>&1)
task_ids+=" "$(osism apply --no-wait --format script memcached 2>&1)
task_ids+=" "$(osism apply --no-wait --format script redis 2>&1)
task_ids+=" "$(osism apply --no-wait --format script mariadb 2>&1)
task_ids+=" "$(osism apply --no-wait --format script rabbitmq 2>&1)
task_ids+=" "$(osism apply --no-wait --format script openvswitch 2>&1)

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ || $OPENSTACK_VERSION == "yoga" ]]; then
    task_ids+=" "$(osism apply --no-wait --format script elasticsearch 2>&1)
    if [[ "$REFSTACK" == "false" ]]; then
        task_ids+=" "$(osism apply --no-wait --format script kibana 2>&1)
    fi
else
    task_ids+=" "$(osism apply --no-wait --format script opensearch 2>&1)
fi

if [[ "$REFSTACK" == "false" ]]; then
    task_ids+=" "$(osism apply --no-wait --format script homer 2>&1)
    task_ids+=" "$(osism apply --no-wait --format script phpmyadmin 2>&1)
fi

osism wait --output --format script --delay 2 $task_ids

osism apply ovn

if [[ "$REFSTACK" == "false" ]]; then
    # NOTE: Run a backup of the database to test the backup function
    osism apply mariadb_backup
fi

osism apply keycloak
osism apply --environment custom keycloak-oidc-client-config
