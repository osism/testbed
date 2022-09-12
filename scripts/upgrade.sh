#!/usr/bin/env bash
set -x
set -e

echo
echo "# UPGRADE"
echo

MANAGER_VERSION=${1:-latest}
CEPH_VERSION=${2:-pacific}
OPENSTACK_VERSION=${3:-yoga}

/opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION
/opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION

export INTERACTIVE=false

# upgrade manager
osism-update-manager
osism reconciler sync
osism apply facts

# upgrade services
sh -c '/opt/configuration/scripts/upgrade-services.sh'
