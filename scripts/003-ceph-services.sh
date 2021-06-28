#!/usr/bin/env bash

export INTERACTIVE=false

osism-ceph testbed
osism-ceph rgws
osism-run custom fetch-ceph-keys
osism-infrastructure cephclient
osism-run custom workarounds-ceph
osism-run custom bootstrap-ceph-dashboard
