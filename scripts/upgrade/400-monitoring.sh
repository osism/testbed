#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

osism apply -a upgrade prometheus
osism apply -a upgrade grafana
