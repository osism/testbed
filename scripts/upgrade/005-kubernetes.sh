#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply kubernetes
osism apply clusterapi
