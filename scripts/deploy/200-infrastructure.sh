#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

osism apply common
osism apply loadbalancer
osism apply openstackclient
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply openvswitch
osism apply ovn

# In OSISM >= 5.0.0, the switch was made from Elasticsearch / Kibana to Opensearch.
if [[ ( $(semver $MANAGER_VERSION 5.0.0) -eq -1 && $MANAGER_VERSION != "latest" ) || $OPENSTACK_VERSION == "yoga" ]]; then
    osism apply elasticsearch
    if [[ "$TEMPEST" == "false" ]]; then
        osism apply kibana
    fi
else
    osism apply opensearch
fi
