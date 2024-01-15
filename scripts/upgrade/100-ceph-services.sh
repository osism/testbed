#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply ceph-rolling_update -e ireallymeanit=yes
osism apply cephclient
