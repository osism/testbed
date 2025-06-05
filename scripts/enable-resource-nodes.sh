#!/usr/bin/env bash

source /opt/manager-vars.sh

remove_node() {
    local node="$1"
    local file="$2"
    awk -v node="$node" '/^- device:/{if(block && block !~ "name: " node) printf "%s", block; block=$0 "\n"; next} {block = block $0 "\n"} END{if(block && block !~ "name: " node) printf "%s", block}' "$file" > temp.$$ && mv temp.$$ "$file"
}

number_of_resource_nodes=$(expr $NUMBER_OF_NODES - 3)

if [[ $number_of_resource_nodes -gt 0 ]]; then
    sed -i "/^#testbed-resource-nodes/s/^#//" /opt/configuration/inventory/20-roles
    for node in $(seq 3 $(expr $NUMBER_OF_NODES - 1)); do
      sed -i "/^#testbed-node-$node/s/^#//" /opt/configuration/inventory/10-custom
    done
    for node in $(seq $(expr $NUMBER_OF_NODES + 1) 9); do
      rm -f /opt/configuration/netbox/resources/300-testbed-node-$node.yml
      remove_node "testbed-node-$node" /opt/configuration/netbox/resources/200-rack-1000.yml
    done
else
    for node in $(seq 0 $(expr $NUMBER_OF_NODES - 1)); do
      sed -i "/^#testbed-node-$node/s/^#//" /opt/configuration/inventory/10-custom
    done
fi
