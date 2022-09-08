#!/usr/bin/env bash
set -e

export INTERACTIVE=false

# NOTE: common + loadbalancer are purposely missing here, as these services
#       are rolled out first.

kolla_services=(
barbican
cinder
designate
elasticsearch
glance
heat
horizon
keystone
kibana
mariadb
memcached
neutron
nova
octavia
openvswitch
ovn
placement
rabbitmq
redis
)

for kolla_service in ${kolla_services[*]}; do
    osism apply --no-wait $kolla_service -e kolla_action=pull
done
