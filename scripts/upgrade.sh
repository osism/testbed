#!/usr/bin/env bash
set -x
set -e

export MANAGER_VERSION=${1:-latest}
CEPH_VERSION=${2:-reef}
OPENSTACK_VERSION=${3:-2024.2}
KOLLA_NAMESPACE=${4:-kolla}

# upgrade manager
sh -c "/opt/configuration/scripts/upgrade-manager.sh $MANAGER_VERSION $CEPH_VERSION $OPENSTACK_VERSION $KOLLA_NAMESPACE"

# upgrade services
sh -c '/opt/configuration/scripts/upgrade-services.sh'
