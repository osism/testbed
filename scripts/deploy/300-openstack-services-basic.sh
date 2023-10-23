#!/usr/bin/env bash
set -e

export INTERACTIVE=false

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply keystone
osism apply placement
osism apply nova
osism apply neutron

osism apply horizon
osism apply glance
osism apply cinder
osism apply designate
osism apply octavia
osism apply kolla-ceph-rgw

if [[ $MANAGER_VERSION =~ ^6\.[0-9]\.[0-9][a-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply magnum
fi

if [[ "$REFSTACK" == "false" ]]; then
    osism apply barbican
fi
