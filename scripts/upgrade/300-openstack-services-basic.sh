#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

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

# We have only been testing Magnum since the OSISM 6.0.0 release. Accordingly, an upgrade
# test only makes sense when upgrading to latest. Can be adjusted with OSISM 7.
if [[ $MANAGER_VERSION == "latest" ]]; then
    osism apply -a upgrade magnum
fi
