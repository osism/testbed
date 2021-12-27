#!/usr/bin/env bash

export INTERACTIVE=false

osism apply ceph-mons
osism apply ceph-mgrs
osism apply ceph-osds
osism apply ceph-mdss
osism apply ceph-crash
osism apply ceph-rgws

osism-run custom fetch-ceph-keys
osism apply cephclient
osism-run custom bootstrap-ceph-dashboard

ceph config set mon auth_allow_insecure_global_id_reclaim false
