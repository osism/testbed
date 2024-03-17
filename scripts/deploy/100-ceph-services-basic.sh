#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible)

# Make sure that no partitions are present
osism apply --environment custom wipe-partitions
osism apply facts

# The callback plugin is not included in the Pacific image. The plugin is no longer
# added there because the builds for Pacific are disabled. This callback plugin will
# therefore not be used during the deployment of Ceph.
if [[ $MANAGER_VERSION == "latest" && $CEPH_VERSION == "pacific" ]]; then
    sed -i "s/osism.commons.still_alive/community.general.yaml/" /opt/configuration/environments/ansible.cfg
fi

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
fi

if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    osism apply ceph-base
    osism apply ceph-mdss
    osism apply ceph-rgws
    osism apply copy-ceph-keys
    osism apply cephclient
    osism apply ceph-bootstrap-dashboard
else
    osism apply ceph
    osism apply copy-ceph-keys
    osism apply cephclient
    osism apply ceph-bootstrap-dashboard
fi

# Once Ceph has been deployed, the callback plugin can be used again.
if [[ $MANAGER_VERSION == "latest" && $CEPH_VERSION == "pacific" ]]; then
    sed -i "s/community.general.yaml/osism.commons.still_alive/" /opt/configuration/environments/ansible.cfg
fi
