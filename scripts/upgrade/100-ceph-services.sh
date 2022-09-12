#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply ceph-rolling_update -e ireallymeanit=yes
osism apply cephclient
