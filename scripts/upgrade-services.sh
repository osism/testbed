#!/usr/bin/env bash
set -x
set -e

echo
echo "# UPGRADE SERVICES"
echo

source /opt/manager-vars.sh

# Set default values if not already set
SKIP_OPENSTACK_UPGRADE=${SKIP_OPENSTACK_UPGRADE:-false}
SKIP_CEPH_UPGRADE=${SKIP_CEPH_UPGRADE:-false}

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# upgrade kubernetes
sh -c '/opt/configuration/scripts/upgrade/500-kubernetes.sh'

# upgrade infrastructure services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/200-infrastructure.sh'
fi

if [[ $SKIP_CEPH_UPGRADE == "false" ]]; then
    # upgrade ceph services
    if [[ $CEPH_STACK == "ceph-ansible" ]]; then
        sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-ansible.sh'
    elif [[ $CEPH_STACK == "rook" ]]; then
        sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-rook.sh'
    fi
fi

# upgrade openstack services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/300-openstack.sh'
fi

if [[ "$TEMPEST" == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/310-openstack-extended.sh'
fi

# upgrade monitoring services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/400-monitoring.sh'
fi

# upgrade clusterapi
sh -c '/opt/configuration/scripts/upgrade/510-clusterapi.sh'
