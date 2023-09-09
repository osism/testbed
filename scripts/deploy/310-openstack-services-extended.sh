#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply gnocchi
osism apply prometheus
osism apply ceilometer
osism apply heat

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "Skip Skyline deployment before OSISM < 5.0.0"
# NOTE: Check on Yoga is sufficient here as this is the last
#       OpenStack release we support before Zed.
elif [[ $OPENSTACK_VERSION == "yoga" ]]; then
    echo "Skip Skyline deployment before OpenStack Zed"
else
    osism apply skyline
fi

if [[ $MANAGER_VERSION =~ ^6\.[0-9]\.[0-9][b-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply senlin
fi
