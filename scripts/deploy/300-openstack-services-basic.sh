#!/usr/bin/env bash
set -e

export INTERACTIVE=false

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply keystone
osism apply placement
osism apply nova
osism apply neutron

task_ids=$(osism apply --no-wait --format script horizon 2>&1)
task_ids+=" "$(osism apply --no-wait --format script glance 2>&1)
task_ids+=" "$(osism apply --no-wait --format script cinder 2>&1)
task_ids+=" "$(osism apply --no-wait --format script barbican 2>&1)
task_ids+=" "$(osism apply --no-wait --format script designate 2>&1)
task_ids+=" "$(osism apply --no-wait --format script octavia 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism manage images --cloud admin --filter Cirros
osism manage images --cloud admin --name "Ubuntu 22.04 Minimal"

osism apply --environment openstack bootstrap-basic -e openstack_version=$OPENSTACK_VERSION
osism apply --environment openstack bootstrap-ceph-rgw

osism apply openstack-health-monitor
