#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' ceph-ansible)

# On the OTC, sometimes old partition entries are still present
# on physical disks. Therefore they are removed at this point.
if [[ -e /etc/OTC_region ]]; then
    osism apply --environment custom wipe-partitions
fi

# The callback plugin is not included in the Pacific image. The plugin is no longer
# added there because the builds for Pacific are disabled. This callback plugin will
# therefore not be used during the deployment of Ceph.
if [[ $MANAGER_VERSION == "latest" && $CEPH_VERSION == "pacific" ]]; then
    sed -i "s/osism.commons.still_alive/community.general.yaml/" /opt/configuration/environments/ansible.cfg
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
