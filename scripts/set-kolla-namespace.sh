#!/usr/bin/env bash
set -x
set -e

NAMESPACE=${1:-osism}

sed -i "s#docker_namespace: .*#docker_namespace: ${NAMESPACE}#g" /opt/configuration/inventory/group_vars/all/kolla.yml
