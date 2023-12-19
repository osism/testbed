#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply -a upgrade gnocchi
osism apply -a upgrade prometheus
osism apply -a upgrade ceilometer
osism apply -a upgrade heat

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
else
    osism apply -a upgrade skyline
fi

if [[ $MANAGER_VERSION =~ ^6\.[0-9]\.[0-9][b-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply -a upgrade senlin
fi
