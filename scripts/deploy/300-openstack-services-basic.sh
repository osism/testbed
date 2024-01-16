#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply keystone
osism apply placement

osism apply --no-wait nova
osism apply --no-wait neutron
osism apply --no-wait horizon
osism apply --no-wait glance
osism apply --no-wait cinder
osism apply --no-wait designate
osism apply --no-wait octavia
osism apply --no-wait kolla-ceph-rgw

if [[ $MANAGER_VERSION =~ ^6\.[0-9]\.[0-9][a-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply --no-wait magnum
fi

if [[ "$REFSTACK" == "false" ]]; then
    osism apply --no-wait barbican
fi

osism wait
