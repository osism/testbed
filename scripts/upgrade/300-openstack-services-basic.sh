#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply -a upgrade keystone
osism apply -a upgrade placement
osism apply -a upgrade nova

task_ids=$(osism apply --no-wait --format script -a upgrade horizon 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade glance 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade neutron 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade cinder 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade barbican 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade designate 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade octavia 2>&1)

osism wait --output --format script --delay 2 $task_ids

# We have only been testing Magnum since the OSISM 6.0.0 release. Accordingly, an upgrade
# test only makes sense when upgrading to latest. Can be adjusted with OSISM 7.
if [[ $MANAGER_VERSION == "latest" ]]; then
    osism apply -a upgrade magnum
fi
