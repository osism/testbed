#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply -a upgrade keystone
osism apply -a upgrade placement
osism apply -a upgrade nova
osism apply -a upgrade horizon
osism apply -a upgrade glance
osism apply -a upgrade neutron
osism apply -a upgrade cinder
osism apply -a upgrade barbican
osism apply -a upgrade designate
osism apply -a upgrade octavia

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9][a-z]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply -a upgrade magnum
fi
