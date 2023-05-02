#!/usr/bin/env bash
set -e

export INTERACTIVE=false

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

osism apply keystone
osism apply placement
osism apply nova
osism apply neutron

task_ids=$(osism apply --no-wait --format script horizon 2>&1)
task_ids+=" "$(osism apply --no-wait --format script glance 2>&1)
task_ids+=" "$(osism apply --no-wait --format script cinder 2>&1)
task_ids+=" "$(osism apply --no-wait --format script designate 2>&1)
task_ids+=" "$(osism apply --no-wait --format script octavia 2>&1)

if [[ "$REFSTACK" == "false" ]]; then
    task_ids+=" "$(osism apply --no-wait --format script barbican 2>&1)
fi

osism wait --output --format script --delay 2 $task_ids

osism apply --environment openstack bootstrap-flavors
osism apply --environment openstack bootstrap-basic -e openstack_version=$OPENSTACK_VERSION
osism apply --environment openstack bootstrap-ceph-rgw

# osism manage images is only available since 5.0.0. To enable the
# testbed to be used with < 5.0.0, here is this check.
if [[ $MANAGER_VERSION == "4.0.0" || $MANAGER_VERSION == "4.1.0" || $MANAGER_VERSION == "4.2.0" || $MANAGER_VERSION == "4.3.0" ]]; then
    osism apply --environment openstack bootstrap-images
else
    osism manage images --cloud admin --filter Cirros
    osism manage images --cloud admin --filter "Ubuntu 22.04 Minimal"
fi

if [[ "$REFSTACK" == "false" ]]; then
    osism apply --environment openstack test
    osism apply openstack-health-monitor
fi
