#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY"
echo

# deploy manager
if [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' osism-ansible 2>/dev/null)" != "healthy" ]]; then
    sh -c '/opt/configuration/scripts/deploy-manager.sh'
fi

# deploy services
sh -c '/opt/configuration/scripts/deploy-services.sh'
