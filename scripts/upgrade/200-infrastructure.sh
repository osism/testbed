#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

key_value_store=$(valkey_or_redis)

osism apply openstackclient
osism apply -a upgrade common
osism apply -a upgrade loadbalancer
osism apply -a upgrade opensearch
osism apply -a upgrade memcached
osism apply -a upgrade "$key_value_store"
osism apply -a upgrade mariadb
osism apply -a upgrade rabbitmq
osism apply -a upgrade openvswitch
osism apply -a upgrade ovn
