#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script gnocchi -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script prometheus -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids

task_ids=$(osism apply --no-wait --format script ceilometer-e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script heat -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script senlin -e kolla_action=upgrade 2>&1)

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION == "4.0.0" || $MANAGER_VERSION == "4.1.0" || $MANAGER_VERSION == "4.2.0" || $MANAGER_VERSION == "4.3.0" ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
else
    task_ids+=" "$(osism apply --no-wait --format script skyline -e kolla_action=upgrade 2>&1)
fi

osism wait --output --format script --delay 2 $task_ids
