#!/usr/bin/env bash
set -e

export INTERACTIVE=false

# NOTE: On the OTC, sometimes old partition entries are still
#       present on physical disks. Therefore they are removed
#       at this point.
if [[ -e /etc/OTC_region ]]; then
    osism apply --environment custom wipe-partitions
fi

# NOTE: ceph-base = ceph-mons + ceph-mgrs + ceph-osds
osism apply ceph-base

osism apply copy-ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

ceph config set mon auth_allow_insecure_global_id_reclaim false

# osism validate is only available since 4.3.0. To enable the
# testbed to be used with < 4.3.0, here is this check.
MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION == "4.0.0" || $MANAGER_VERSION == "4.1.0" || $MANAGER_VERSION == "4.2.0" ]]; then
    echo "ceph validate not possible with OSISM < 4.3.0"
else
    osism apply facts
    osism validate ceph-mons
    osism validate ceph-mgrs
    osism validate ceph-osds
fi
