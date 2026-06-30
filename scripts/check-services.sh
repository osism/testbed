#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# check ceph services
sh -c '/opt/configuration/scripts/check/100-ceph-with-ansible.sh'

# check infrastructure services
sh -c '/opt/configuration/scripts/check/200-infrastructure.sh'

# check openstack services
sh -c '/opt/configuration/scripts/check/300-openstack.sh'
