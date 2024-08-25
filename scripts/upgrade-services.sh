#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# upgrade kubernetes
sh -c '/opt/configuration/scripts/upgrade/005-kubernetes.sh'

# upgrade infrastructure services
sh -c '/opt/configuration/scripts/upgrade/200-infrastructure-services.sh'

# upgrade ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-services.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-rook-services.sh'
fi

# upgrade openstack services
sh -c '/opt/configuration/scripts/upgrade/300-openstack-services.sh'
sh -c '/opt/configuration/scripts/upgrade/310-openstack-services-extended.sh'

# upgrade monitoring services
sh -c '/opt/configuration/scripts/upgrade/400-monitoring-services.sh'
