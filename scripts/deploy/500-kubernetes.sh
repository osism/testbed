#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

if [[ $(semver $MANAGER_VERSION 8.0.3) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    osism apply frr
    osism apply kubernetes
    osism apply copy-kubeconfig
fi
