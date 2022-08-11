#!/usr/bin/env bash

export INTERACTIVE=false

# NOTE: On the OTC, sometimes old partition entries are still
#       present on physical disks. Therefore they are removed
#       at this point.
if [[ -e /etc/OTC_region ]]; then
    osism apply --environment custom wipe-partitions
fi

osism apply ceph-mons
osism apply ceph-mgrs
osism apply ceph-osds
osism apply ceph-mdss
osism apply ceph-crash
osism apply ceph-rgws

osism apply copy-ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

ceph config set mon auth_allow_insecure_global_id_reclaim false
