#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply common -e kolla_action=upgrade
osism apply loadbalancer -e kolla_action=upgrade

task_ids=$(osism apply --no-wait --format script openstackclient 2>&1)
task_ids+=" "$(osism apply --no-wait --format script elasticsearch -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script memcached -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script redis -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script mariadb -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script kibana -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script rabbitmq -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism apply openvswitch -e kolla_action=upgrade

if [[ $OPENSTACK_VERSION =~ (xena|yoga) ]]; then
    osism apply ovn
else
    osism apply ovn-db
    osism apply ovn-controller
fi
