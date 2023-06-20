#!/usr/bin/env bash
#
set -e

export INTERACTIVE=false

kolla_services=(
barbican
cinder
common
designate
glance
heat
horizon
keystone
loadbalancer
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
