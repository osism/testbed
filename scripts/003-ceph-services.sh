#!/usr/bin/env bash

export INTERACTIVE=false

osism apply ceph-mon
osism apply ceph-mgr
osism apply ceph-osd
osism apply ceph-mds
osism apply ceph-crash
osism apply ceph-rgws

osism-run custom fetch-ceph-keys
osism apply cephclient
osism-run custom bootstrap-ceph-dashboard

ceph config set mon auth_allow_insecure_global_id_reclaim false
