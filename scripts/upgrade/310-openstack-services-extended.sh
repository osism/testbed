#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script -a upgrade gnocchi 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade prometheus 2>&1)

osism wait --output --format script --delay 2 "$task_ids"

task_ids=$(osism apply --no-wait --format script -a upgrade ceilometer 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade heat 2>&1)

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
else
    task_ids+=" "$(osism apply --no-wait --format script -a upgrade skyline 2>&1)
fi

if [[ $MANAGER_VERSION =~ ^6\.[0-9]\.[0-9][b-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    task_ids+=" "$(osism apply --no-wait --format script -a upgrade senlin 2>&1)
fi

osism wait --output --format script --delay 2 "$task_ids"
