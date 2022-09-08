#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

echo
echo "# CHECK"
echo

# list containers

for node in testbed-manager testbed-node-0 testbed-node-1 testbed-node-2; do
    echo
    echo "# Containers @ $node"
    echo
    osism container $node
done


# check services
sh -c '/opt/configuration/scripts/check-services.sh'
