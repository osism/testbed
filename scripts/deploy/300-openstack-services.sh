#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply keystone
osism apply placement
osism apply neutron
osism apply ironic
osism apply nova

osism apply horizon
osism apply skyline
osism apply glance
osism apply cinder
osism apply barbican
osism apply designate
osism apply octavia
osism apply ceilometer
osism apply aodh

osism apply kolla-ceph-rgw

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply clusterapi
    osism apply magnum
fi
