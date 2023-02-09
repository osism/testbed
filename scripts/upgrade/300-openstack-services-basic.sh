#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply keystone -e kolla_action=upgrade
osism apply placement -e kolla_action=upgrade
osism apply nova -e kolla_action=upgrade

task_ids=$(osism apply --no-wait --format script horizon -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script glance -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script neutron -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script cinder -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script barbican -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script designate -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script octavia -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids
