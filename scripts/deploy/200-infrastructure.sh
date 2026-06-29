#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

key_value_store=$(valkey_or_redis)

osism apply openstackclient
osism apply common
osism apply loadbalancer
osism apply opensearch
osism apply memcached
osism apply "$key_value_store"
osism apply mariadb
osism apply rabbitmq
osism apply openvswitch
osism apply ovn
