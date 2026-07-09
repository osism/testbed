#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# deploy helper services
sh -c '/opt/configuration/scripts/deploy/001-helpers.sh'

# deploy infrastructure services
sh -c '/opt/configuration/scripts/deploy/200-infrastructure.sh'

# deploy ceph services
sh -c '/opt/configuration/scripts/deploy/100-ceph-with-ansible.sh'

# deploy openstack services
sh -c '/opt/configuration/scripts/deploy/300-openstack.sh'

# deploy monitoring services
sh -c '/opt/configuration/scripts/deploy/400-monitoring.sh'
