#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

osism apply -a upgrade prometheus
osism apply -a upgrade grafana

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply thanos_sidecar
fi
