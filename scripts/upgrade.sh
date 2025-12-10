#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

OLD_MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OLD_OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

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
    if [[ $CEPH_VERSION != "skip" ]]; then
        /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
        echo "export SKIP_CEPH_UPGRADE=false" | sudo tee -a /opt/manager-vars.sh
    else
        echo "export SKIP_CEPH_UPGRADE=true" | sudo tee -a /opt/manager-vars.sh
    fi
    if [[ $OPENSTACK_VERSION != "skip" ]]; then
        /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
        echo "export SKIP_OPENSTACK_UPGRADE=false" | sudo tee -a /opt/manager-vars.sh
    else
        echo "export SKIP_OPENSTACK_UPGRADE=true" | sudo tee -a /opt/manager-vars.sh
    fi
fi

/opt/configuration/scripts/set-kolla-namespace.sh $KOLLA_NAMESPACE

# Sync configuration repository
sh -c '/opt/configuration/scripts/sync-configuration-repository.sh'

# enable new kubernetes service
if [[ $(semver $OLD_MANAGER_VERSION 6.0.0) -ge 0 ]]; then
    echo "enable_osism_kubernetes: true" >> /opt/configuration/environments/manager/configuration.yml
fi

if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 || $(semver $OPENSTACK_VERSION 2025.1 ) -ge 0 ]]; then
    sed -i "/^om_enable_rabbitmq_high_availability:/d" /opt/configuration/environments/kolla/configuration.yml
    sed -i "/^om_enable_rabbitmq_quorum_queues:/d" /opt/configuration/environments/kolla/configuration.yml
fi

# Check if upgrade crosses the RabbitMQ vhost migration boundary
MANAGER_UPGRADE_CROSSES_10=$([ $(semver "$OLD_MANAGER_VERSION" 9.5.0) -le 0 ] && [ $(semver "$MANAGER_VERSION" 10.0.0-0) -ge 0 ] && echo true || echo false)
OPENSTACK_UPGRADE_CROSSES_2025=$([ $(semver "$OLD_OPENSTACK_VERSION" 2024.2) -le 0 ] && [ $(semver "$OPENSTACK_VERSION" 2025.1) -ge 0 ] && echo true || echo false)

if [[ $MANAGER_UPGRADE_CROSSES_10 == "true" || $OPENSTACK_UPGRADE_CROSSES_2025 == "true" ]]; then
    echo 'om_rpc_vhost: openstack' >> /opt/configuration/environments/kolla/configuration.yml
    echo 'om_notify_vhost: openstack' >> /opt/configuration/environments/kolla/configuration.yml
    sed -i "s#manager_listener_broker_vhost: .*#manager_listener_broker_vhost: /openstack#g" /opt/configuration/environments/manager/configuration.yml
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

# disable ara service
if [[ "$IS_ZUUL" == "true" || "$ARA" == "false" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# refresh facts & sync the inventory
sync_inventory
osism apply facts

# upgrade services
sh -c '/opt/configuration/scripts/upgrade-services.sh'
