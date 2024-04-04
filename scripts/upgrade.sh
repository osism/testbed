#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

echo
echo "# UPGRADE"
echo

export MANAGER_VERSION=${1:-latest}
CEPH_VERSION=${2:-quincy}
OPENSTACK_VERSION=${3:-2023.2}
KOLLA_NAMESPACE=${4:-osism}

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# NOTE: For a stable release, the versions of Ceph and OpenStack to use
#       are set by the version of the stable release (set via the
#       manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
fi

/opt/configuration/scripts/set-kolla-namespace.sh $KOLLA_NAMESPACE

# Sync testbed repo with generics
pushd /opt/configuration
pip3 install --no-cache-dir python-gilt==1.2.3
export PATH=$PATH:/home/dragon/.local/bin
GILT=$(which gilt)
${GILT} overlay
${GILT} overlay
popd

# upgrade manager
osism update manager

# wait for manager service
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

docker compose --project-directory /opt/manager ps
docker compose --project-directory /opt/netbox ps

# disable ara service
if [[ -e /etc/osism-ci-image ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# refresh facts & reconcile the inventory
osism reconciler sync
osism apply facts

# upgrade services
sh -c '/opt/configuration/scripts/upgrade-services.sh'
