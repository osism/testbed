#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

# osism manage flavors --recommended is only available since 7.0.2.
if [[ $(semver $MANAGER_VERSION 7.0.2) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    osism manage flavors --recommended
else
    osism apply --environment openstack bootstrap-flavors
fi

osism apply --environment openstack bootstrap-basic

# osism manage images is only available since 5.0.0.
if [[ $(semver $MANAGER_VERSION 5.0.0) -eq -1 ]]; then
    osism apply --environment openstack bootstrap-images
else
    osism manage images --cloud admin --filter Cirros
fi
