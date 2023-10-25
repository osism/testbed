#!/usr/bin/env bash
set -e

export INTERACTIVE=false

kolla_services=(
barbican
cinder
common
designate
glance
grafana
heat
horizon
keystone
loadbalancer
mariadb
memcached
neutron
nova
octavia
opensearch
openvswitch
ovn
placement
rabbitmq
redis
)

for kolla_service in ${kolla_services[*]}; do
    osism apply --no-wait -a pull $kolla_service
done
