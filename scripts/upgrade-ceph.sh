#!/usr/bin/env bash
set -x
set -e

echo
echo "# UPGRADE"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

export MANAGER_VERSION=${1:-latest}
CEPH_VERSION=${2:-pacific}

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# NOTE: For a stable release, the versions of Ceph and OpenStack to use
#       are set by the version of the stable release (set via the
#       manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
fi

# Sync configuration repository
sh -c '/opt/configuration/scripts/sync-configuration-repository.sh'

# upgrade manager
osism update manager
docker compose --project-directory /opt/manager ps

osism reconciler sync
osism apply facts

# upgrade services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-ansible.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/upgrade/100-ceph-with-rook.sh'
fi
