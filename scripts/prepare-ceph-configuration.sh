#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

# Make sure that no partitions are present
osism apply --environment custom wipe-partitions
osism apply facts

# In preparation for deployment with Rook, the pre-built LVM2 volumes are always used
# from OSISM 7 onwards.
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    sed -i "/^devices:/d" /opt/configuration/inventory/group_vars/testbed-nodes.yml
    osism apply ceph-configure-lvm-volumes
    for node in $(find /opt/configuration/inventory/host_vars -mindepth 1 -type d); do
        if [[ -e /tmp/$(basename $node)-ceph-lvm-configuration.yml ]]; then
            cp /tmp/$(basename $node)-ceph-lvm-configuration.yml /opt/configuration/inventory/host_vars/$(basename $node)/ceph-lvm-configuration.yml
        fi
    done
    osism reconciler sync
    osism apply ceph-create-lvm-devices
    osism apply facts
fi
