#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply openstackclient
osism apply -a upgrade common
osism apply -a upgrade loadbalancer
osism apply -a upgrade opensearch
osism apply -a upgrade memcached
osism apply -a upgrade redis
osism apply -a upgrade mariadb
osism apply -a upgrade rabbitmq
osism apply -a upgrade openvswitch
osism apply -a upgrade ovn
