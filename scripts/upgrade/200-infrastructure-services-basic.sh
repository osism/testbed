#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply common -e kolla_action=upgrade
osism apply loadbalancer -e kolla_action=upgrade

osism apply openstackclient
osism apply elasticsearch -e kolla_action=upgrade
osism apply memcached -e kolla_action=upgrade
osism apply redis -e kolla_action=upgrade
osism apply mariadb -e kolla_action=upgrade
osism apply kibana -e kolla_action=upgrade
osism apply rabbitmq -e kolla_action=upgrade

osism apply openvswitch -e kolla_action=upgrade
osism apply ovn -e kolla_action=upgrade
