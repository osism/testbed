#!/usr/bin/env bash
set -x
set -e

DOCKER_REGISTRY=${1:-osism.harbor.regio.digital}

sed -i "s#ceph_docker_registry: .*#ceph_docker_registry: ${DOCKER_REGISTRY}#g" /opt/configuration/environments/configuration.yml
sed -i "s#docker_registry_ansible: .*#docker_registry_ansible: ${DOCKER_REGISTRY}#g" /opt/configuration/environments/configuration.yml
sed -i "s#docker_registry_kolla: .*#docker_registry_kolla: ${DOCKER_REGISTRY}#g" /opt/configuration/environments/configuration.yml
sed -i "s#docker_registry_netbox: .*#docker_registry_netbox: ${DOCKER_REGISTRY}#g" /opt/configuration/environments/configuration.yml

if [[ "$DOCKER_REGISTRY" == "osism.harbor.regio.digital" ]]; then
    sed -i "s/docker_namespace: osism/docker_namespace: kolla/" /opt/configuration/environments/kolla/configuration.yml
fi
