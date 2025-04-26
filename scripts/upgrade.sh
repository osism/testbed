#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

OLD_MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

echo
echo "# UPGRADE"
echo

export MANAGER_VERSION=${1:-latest}
CEPH_VERSION=${2:-reef}
OPENSTACK_VERSION=${3:-2024.2}
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

# Sync configuration repository
sh -c '/opt/configuration/scripts/sync-configuration-repository.sh'

# enable new kubernetes service
if [[ $(semver $OLD_MANAGER_VERSION 6.0.0) -ge 0 ]]; then
    echo "enable_osism_kubernetes: true" >> /opt/configuration/environments/manager/configuration.yml
fi

# upgrade manager
osism update manager

# wait for manager service
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    wait_for_container_healthy 60 ceph-ansible
fi
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

docker compose --project-directory /opt/manager ps
docker compose --project-directory /opt/netbox ps

# disable ara service
if [[ "$IS_ZUUL" == "true" || "$ARA" == "false" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# refresh facts & sync the inventory
sync_inventory
osism apply facts

# upgrade services
sh -c '/opt/configuration/scripts/upgrade-services.sh'
