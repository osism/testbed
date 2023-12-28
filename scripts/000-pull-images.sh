#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false
source /opt/manager-vars.sh

echo
echo "# PULL IMAGES"
echo

if [[ $IS_ZUUL == "true" ]]; then
    # Wait for task in the background to avoid bug/feature with 60 seconds
    # timeout for custom plays.
    task_id=$(osism apply --no-wait --format script -e custom import-images | tail -n 1 | tr -d '\n\r')
    osism wait --output --format script --delay 2 $task_id
fi

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
    echo "+ osism apply -a pull $kolla_service"
    osism apply -a pull $kolla_service
done
