#!/usr/bin/env bash

export INTERACTIVE=false

osism-ceph testbed
osism-ceph rgws
osism-run custom fetch-ceph-keys
osism-infrastructure helper --tags cephclient
