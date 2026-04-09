#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

DOCKER_REGISTRY=${1:-registry.osism.tech}

sed -i "s#ceph_docker_registry: .*#ceph_docker_registry: ${DOCKER_REGISTRY}#g" /opt/configuration/inventory/group_vars/all/registries.yml
sed -i "s#docker_registry_ansible: .*#docker_registry_ansible: ${DOCKER_REGISTRY}#g" /opt/configuration/inventory/group_vars/all/registries.yml
sed -i "s#docker_registry_kolla: .*#docker_registry_kolla: ${DOCKER_REGISTRY}#g" /opt/configuration/inventory/group_vars/all/registries.yml
sed -i "s#docker_registry_netbox: .*#docker_registry_netbox: ${DOCKER_REGISTRY}#g" /opt/configuration/inventory/group_vars/all/registries.yml

if [[ "$DOCKER_REGISTRY" == "registry.osism.tech" ]]; then
    if [[ "$MANAGER_VERSION" == "latest" ]]; then
        /opt/configuration/scripts/set-kolla-namespace.sh kolla
    elif [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 ]]; then
        /opt/configuration/scripts/set-kolla-namespace.sh "kolla/release/$OPENSTACK_VERSION"
    else
        /opt/configuration/scripts/set-kolla-namespace.sh kolla/release
    fi
fi
