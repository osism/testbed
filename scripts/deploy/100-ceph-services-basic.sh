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
