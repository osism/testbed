#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# prepare the ceph deployment
sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

# deploy everything

# required by k3s, not handled by nutshell
osism apply frr

echo
echo "--> DEPLOY IN A NUTSHELL -- START -- $(date)"
echo

# python-osism picks the nutshell Ceph backend by OSISM release, and from
# OSISM 11 on it takes --ceph-backend to choose otherwise. Pass CEPH_STACK so
# the testbed's backend is the one deployed. Older releases know only
# ceph-ansible and have no such option.
ceph_backend=()
if [[ $MANAGER_VERSION == "latest" || $(semver $MANAGER_VERSION 11.0.0-0) -ge 0 ]]; then
    ceph_backend=(--ceph-backend "${CEPH_STACK:-cephadm}")
fi
osism apply "${ceph_backend[@]}" nutshell

# wait for all deployments
osism wait --output --refresh 20

echo
echo "--> DEPLOY IN A NUTSHELL -- END -- $(date)"
echo
