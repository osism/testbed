#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

osism apply netdata
osism apply prometheus
osism apply grafana
