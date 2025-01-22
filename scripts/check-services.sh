#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# check ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/check/100-ceph-with-ansible.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/check/100-ceph-with-rook.sh'
fi

# check infrastructure services
sh -c '/opt/configuration/scripts/check/200-infrastructure.sh'

# check openstack services
sh -c '/opt/configuration/scripts/check/300-openstack.sh'
