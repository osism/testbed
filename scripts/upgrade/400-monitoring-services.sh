#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply -a upgrade prometheus
osism apply -a upgrade grafana
