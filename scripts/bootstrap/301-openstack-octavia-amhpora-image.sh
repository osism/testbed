#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    osism manage image octavia
fi
