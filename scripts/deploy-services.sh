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
sh -c '/opt/configuration/scripts/deploy/001-helper-services.sh'

# deploy kubernetes
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
  sh -c '/opt/configuration/scripts/deploy/005-kubernetes.sh'
fi

# deploy infrastructure services
sh -c '/opt/configuration/scripts/deploy/200-infrastructure-services-basic.sh'

# deploy service services
sh -c '/opt/configuration/scripts/deploy/100-ceph-services-basic.sh'

# deploy openstack services
sh -c '/opt/configuration/scripts/deploy/300-openstack-services-basic.sh'

if [[ "$REFSTACK" == "false" ]]; then
    # deploy extended openstack services
    sh -c '/opt/configuration/scripts/deploy/310-openstack-services-extended.sh'
fi

# deploy openstack baremetal services
sh -c '/opt/configuration/scripts/deploy/320-openstack-services-baremetal.sh'

# deploy monitoring services
sh -c '/opt/configuration/scripts/deploy/400-monitoring-services.sh'
