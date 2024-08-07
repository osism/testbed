#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
## currently not implemented
# CEPH_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.ceph" }}' osism-ansible)

# check/deploy kubernetes
if command -v kubectl &> /dev/null; then
    K8S_READY_COUNT=$(kubectl get nodes | grep -c Ready)
    if [[ $K8S_READY_COUNT == 0 ]]; then
        /opt/configuration/scripts/deploy/005-kubernetes.sh
    fi
else
    /opt/configuration/scripts/deploy/005-kubernetes.sh
fi

osism apply rook-operator
osism apply rook
osism apply rook-fetch-keys

echo "cephclient_install_type: rook" >> /opt/configuration/environments/infrastructure/configuration.yml
osism apply cephclient
