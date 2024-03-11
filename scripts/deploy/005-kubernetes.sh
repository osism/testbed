#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

osism apply kubernetes
osism apply clusterapi

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply copy-kubeconfig
    osism apply kubernetes-dashboard
fi
