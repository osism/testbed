#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

osism apply -a upgrade gnocchi
osism apply -a upgrade manila
