#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

osism apply netdata
osism apply prometheus
osism apply grafana

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply thanos_sidecar
fi
