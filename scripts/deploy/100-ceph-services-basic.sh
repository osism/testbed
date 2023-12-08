#!/usr/bin/env bash
set -e

export INTERACTIVE=false

# NOTE: On the OTC, sometimes old partition entries are still
#       present on physical disks. Therefore they are removed
#       at this point.
if [[ -e /etc/OTC_region ]]; then
    osism apply --environment custom wipe-partitions
fi

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ "$REFSTACK" == "false" ]]; then
    if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
        osism apply ceph-base
        osism apply ceph-mdss
        osism apply ceph-rgws
    else
        osism apply ceph -e enable_ceph_mds=true -e enable_ceph_rgw=true
    fi
else
    if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
        osism apply ceph-base
    else
        osism apply ceph
    fi
fi

osism apply copy-ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

# osism validate is only available since 5.0.0. To enable the
# testbed to be used with < 5.0.0, here is this check.
MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "ceph validate not possible with OSISM < 4.3.0"
else
    osism apply facts
    osism validate ceph-mons
    osism validate ceph-mgrs
    osism validate ceph-osds
fi
