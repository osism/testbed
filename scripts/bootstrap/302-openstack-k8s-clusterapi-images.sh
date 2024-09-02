#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    osism manage image clusterapi --filter 1.30
fi
