#!/usr/bin/env bash

source /opt/manager-vars.sh

number_of_resource_nodes=$(expr $NUMBER_OF_NODES - 3)

if [[ $number_of_resource_nodes -gt 0 ]]; then
    sed -i "/^#testbed-resource-nodes/s/^#//" /opt/configuration/inventory/20-roles
    for node in $(seq 3 $(expr $NUMBER_OF_NODES - 1)); do
      sed -i "/^#testbed-node-$node/s/^#//" /opt/configuration/inventory/10-custom
    done
else
    for node in $(seq 0 $(expr $NUMBER_OF_NODES - 1)); do
      sed -i "/^#testbed-node-$node/s/^#//" /opt/configuration/inventory/10-custom
    done
fi
