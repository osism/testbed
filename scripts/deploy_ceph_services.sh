#!/usr/bin/env bash

export INTERACTIVE=false

osism-ceph env-hci
osism-run custom fetch-ceph-keys
osism-infrastructure helper --tags cephclient
