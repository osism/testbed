#!/usr/bin/env bash

export INTERACTIVE=false

osism-ceph testbed
osism-ceph rgws
osism-run custom fetch-ceph-keys
osism-infrastructure cephclient
osism-run custom bootstrap-ceph-dashboard
ceph config set mon auth_allow_insecure_global_id_reclaim false

