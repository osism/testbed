#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script gnocchi -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script prometheus -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids

task_ids=$(osism apply --no-wait --format script ceilometer-e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script heat -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script senlin -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids
