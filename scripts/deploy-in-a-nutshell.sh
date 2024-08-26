#!/usr/bin/env bash
set -e

# do not use the local registry
sh -c '/opt/configuration/scripts/set-docker-registry.sh'

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# prepare the ceph deployment
sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

# deploy everything

echo
echo "--> DEPLOY IN A NUTSHELL -- START -- $(date)"
echo

osism apply nutshell

# wait for all deployments
osism wait --output --refresh 20

echo
echo "--> DEPLOY IN A NUTSHELL -- END -- $(date)"
echo
