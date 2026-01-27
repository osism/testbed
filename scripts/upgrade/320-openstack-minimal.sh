#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

osism apply -a upgrade keystone
osism apply -a upgrade placement
osism apply -a upgrade neutron
osism apply -a upgrade nova
osism apply -a upgrade horizon
osism apply -a upgrade glance
osism apply -a upgrade cinder
osism apply -a upgrade designate

# In OSISM >= 7.0.0 the persistence feature in Octavia was enabled by default.
# This requires an additional database, which is only created when Octavia play
# is run in bootstrap mode first.
if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    osism apply -a bootstrap octavia
fi

osism apply -a upgrade octavia
