#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[2-9]$ || $MANAGER_VERSION == "latest" ]]; then
    osism manage flavors --recommended
else
    osism apply --environment openstack bootstrap-flavors
fi

osism apply --environment openstack bootstrap-basic

# osism manage images is only available since 5.0.0. To enable the
# testbed to be used with < 5.0.0, here is this check.
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    osism apply --environment openstack bootstrap-images
else
    osism manage images --cloud admin --filter Cirros
fi
