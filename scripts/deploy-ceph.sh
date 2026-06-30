#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY CEPH SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# deploy ceph services
sh -c '/opt/configuration/scripts/deploy/100-ceph-with-ansible.sh'
