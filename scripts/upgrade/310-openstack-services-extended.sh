#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

osism apply -a upgrade gnocchi
osism apply -a upgrade ceilometer
osism apply -a upgrade heat

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
else
    osism apply -a upgrade skyline
fi

# NOTE: disabled because we have not yet deployed Senlin in the previous version of OSISM
# MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
# if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
#     osism apply -a upgrade senlin
# fi
