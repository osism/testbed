#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

osism apply --no-wait netdata
osism apply --no-wait prometheus
osism apply --no-wait grafana

osism wait
