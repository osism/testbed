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
sh -c '/opt/configuration/scripts/deploy/500-kubernetes.sh'

# deploy infrastructure services
sh -c '/opt/configuration/scripts/deploy/200-infrastructure-services.sh'

# deploy ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-ceph-services.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-rook-services.sh'
fi

# deploy openstack services
sh -c '/opt/configuration/scripts/deploy/300-openstack-services.sh'

if [[ "$TEMPEST" == "false" ]]; then
    # deploy extended openstack services
    sh -c '/opt/configuration/scripts/deploy/310-openstack-services-extended.sh'
fi

# deploy monitoring services
sh -c '/opt/configuration/scripts/deploy/400-monitoring-services.sh'

# deploy clusterapi
sh -c '/opt/configuration/scripts/deploy/510-clusterapi.sh'
