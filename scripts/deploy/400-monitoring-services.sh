#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply netdata
osism apply prometheus
osism apply grafana
