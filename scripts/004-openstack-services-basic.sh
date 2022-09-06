#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply keystone
osism apply placement
osism apply nova

task_ids=$(osism apply --no-wait --format script horizon 2>&1)
task_ids+=" "$(osism apply --no-wait --format script glance 2>&1)
task_ids+=" "$(osism apply --no-wait --format script neutron 2>&1)
task_ids+=" "$(osism apply --no-wait --format script cinder 2>&1)
task_ids+=" "$(osism apply --no-wait --format script barbican 2>&1)
task_ids+=" "$(osism apply --no-wait --format script designate 2>&1)
task_ids+=" "$(osism apply --no-wait --format script heat 2>&1)
task_ids+=" "$(osism apply --no-wait --format script octavia 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism apply --environment openstack bootstrap-keystone
osism apply --environment openstack bootstrap-basic
osism apply --environment openstack bootstrap-ceph-rgw

osism apply openstack-health-monitor
