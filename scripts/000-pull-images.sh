#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false
source /opt/manager-vars.sh

echo
echo "# PULL IMAGES"
echo

if [[ "$MANAGER_VERSION" == "latest" ]]; then
    # Only works as with OSISM >= 6.1.0 as the osism.common.still_alive
    # callback plugin can then be used.
    osism apply -e custom pull-images
else
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
fi
