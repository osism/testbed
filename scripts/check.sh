#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

echo
echo "# CHECK"
echo

# list containers & images

for node in testbed-manager testbed-node-0 testbed-node-1 testbed-node-2; do
    # osism container is only available since 5.0.0. To enable the
    # testbed to be used with < 5.0.0, here is this check.
    if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
        echo
        echo "## Containers @ $node"
        echo
        ssh $node docker ps

        echo
        echo "## Images @ $node"
        echo
        ssh $node docker images
    else
        echo
        echo "## Containers @ $node"
        echo
        osism container $node ps

        echo
        echo "## Images @ $node"
        echo
        osism container $node images
    fi

done

# check services
sh -c '/opt/configuration/scripts/check-services.sh'
