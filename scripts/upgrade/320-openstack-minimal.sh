#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh
source /opt/configuration/scripts/manager-version.sh

if [[ $RABBITMQ3TO4 == "true" ]]; then
    osism migrate rabbitmq3to4 prepare
    osism migrate rabbitmq3to4 list
    osism migrate rabbitmq3to4 list-exchanges
fi

osism apply -a upgrade keystone
osism apply -a upgrade placement
osism apply -a upgrade neutron

if [[ $RABBITMQ3TO4 == "true" ]]; then
    osism apply -a reconfigure nova
    osism apply nova-update-cell-mappings
    osism apply -a upgrade nova
else
    osism apply -a upgrade nova
fi

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

if [[ $RABBITMQ3TO4 == "true" ]]; then
    osism migrate rabbitmq3to4 delete
    osism migrate rabbitmq3to4 list
    osism migrate rabbitmq3to4 list --vhost openstack --quorum

    osism migrate rabbitmq3to4 delete-exchanges
    osism migrate rabbitmq3to4 list-exchanges
fi
