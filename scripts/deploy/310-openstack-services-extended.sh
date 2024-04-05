#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

osism apply gnocchi
osism apply ceilometer
osism apply heat

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
# NOTE: Check on Yoga is sufficient here as this is the last
#       OpenStack release we support before Zed.
elif [[ $OPENSTACK_VERSION == "yoga" ]]; then
    echo "Skip Skyline deployment before OpenStack Zed"
else
    osism apply skyline
fi

# NOTE: disabled because we have not yet deployed Senlin in the previous version of OSISM
# if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
#     osism apply senlin
# fi
