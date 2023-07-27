#!/usr/bin/env bash
set -x
set -e

NAMESPACE=${1:-kolla}

sed -i "s#docker_namespace: .*#docker_namespace: ${NAMESPACE}#g" /opt/configuration/environments/kolla/configuration.yml
