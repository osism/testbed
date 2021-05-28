#!/usr/bin/env bash

number_of_secondary_nodes=$(expr $1 - 3)

if [[ $number_of_secondary_nodes -gt 0 ]]; then
    for node in $(seq 4 $(expr $1 - 1)); do
      sed -i "/^#.*testbed-node-$node/s/^#//" /opt/configuration/inventory/10-custom
    done
fi
