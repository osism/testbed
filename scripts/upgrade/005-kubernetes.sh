#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

if [[ $MANAGER_VERSION == "latest" ]]; then
    osism apply kubernetes
    osism apply clusterapi
fi
