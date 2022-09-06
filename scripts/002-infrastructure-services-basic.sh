#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply common
osism apply loadbalancer

task_ids=$(osism apply --no-wait --format script keycloak 2>&1)
task_ids+=" "$(osism apply --no-wait --format script openstackclient 2>&1)
task_ids+=" "$(osism apply --no-wait --format script elasticsearch 2>&1)
task_ids+=" "$(osism apply --no-wait --format script memcached 2>&1)
task_ids+=" "$(osism apply --no-wait --format script redis 2>&1)
task_ids+=" "$(osism apply --no-wait --format script mariadb 2>&1)
task_ids+=" "$(osism apply --no-wait --format script kibana 2>&1)
task_ids+=" "$(osism apply --no-wait --format script rabbitmq 2>&1)
task_ids+=" "$(osism apply --no-wait --format script homer 2>&1)
task_ids+=" "$(osism apply --no-wait --format script phpmyadmin 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism apply openvswitch
osism apply ovn

osism apply --environment custom keycloak-oidc-client-config

# NOTE: Run a backup of the database to test the backup function
osism apply mariadb_backup
