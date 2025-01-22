#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# upgrade kubernetes
sh -c '/opt/configuration/scripts/upgrade/500-kubernetes.sh'

# upgrade infrastructure services
sh -c '/opt/configuration/scripts/upgrade/200-infrastructure.sh'

# upgrade ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-ansible.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-rook.sh'
fi

# upgrade openstack services
sh -c '/opt/configuration/scripts/upgrade/300-openstack.sh'

if [[ "$TEMPEST" == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/310-openstack-extended.sh'
fi

# upgrade monitoring services
sh -c '/opt/configuration/scripts/upgrade/400-monitoring.sh'

# upgrade clusterapi
sh -c '/opt/configuration/scripts/upgrade/510-clusterapi.sh'
