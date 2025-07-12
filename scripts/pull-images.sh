#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

echo
echo "# PULL IMAGES"
echo

if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    # Only works as with OSISM >= 7.0.0 as the osism.common.still_alive
    # callback plugin can then be used.
    osism apply --no-wait -r 2 -e custom pull-images
else
    kolla_services=(
    barbican
    cinder
    common
    designate
    glance
    grafana
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
        osism apply --no-wait -a pull $kolla_service
    done
fi
