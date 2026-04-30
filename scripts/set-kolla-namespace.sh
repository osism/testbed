#!/usr/bin/env bash
set -x
set -e

SYNC=false
if [[ "$1" == "--sync" ]]; then
    SYNC=true
    shift
fi

NAMESPACE=${1:-osism}

sed -i "s#docker_namespace: .*#docker_namespace: ${NAMESPACE}#g" /opt/configuration/inventory/group_vars/all/kolla.yml

# --sync makes the new namespace visible to the next `osism apply` immediately,
# instead of waiting for the inventory-reconciler's periodic tick.
if [[ "$SYNC" == "true" ]]; then
    osism sync inventory
fi
