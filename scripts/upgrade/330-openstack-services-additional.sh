#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

osism apply -a upgrade aodh
osism apply -a upgrade manila
