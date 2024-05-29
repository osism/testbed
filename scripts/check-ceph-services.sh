#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# check ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/check/100-ceph-services.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/check/100-rook-services.sh'
fi
