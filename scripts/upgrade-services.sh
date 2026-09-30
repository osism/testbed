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

# Ceph upgrades under cephadm run through "ceph orch upgrade", which the
# testbed does not drive. Only the ceph-ansible upgrade below exists, and it
# cannot upgrade a cephadm cluster, so refuse rather than run it.
if [[ ${CEPH_STACK:-ceph-ansible} == "cephadm" && $SKIP_CEPH_UPGRADE == "false" ]]; then
    echo "Upgrading Ceph with cephadm is not supported by the testbed."
    echo "Set SKIP_CEPH_UPGRADE=true to upgrade the remaining services."
    exit 1
fi

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# upgrade infrastructure services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/200-infrastructure.sh'
fi

if [[ $SKIP_CEPH_UPGRADE == "false" ]]; then
    # upgrade ceph services
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-ansible.sh'
fi

# upgrade openstack services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/300-openstack.sh'
fi

# upgrade monitoring services
if [[ $SKIP_OPENSTACK_UPGRADE == "false" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/400-monitoring.sh'
fi
