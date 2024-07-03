#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY CEPH SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# deploy ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-ceph-services-basic.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-rook-services.sh'
fi
