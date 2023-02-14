#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids+=" "$(osism apply --no-wait --format script aodh -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script heat -e kolla_action=upgrade 2>&1)
task_ids+=" "$(osism apply --no-wait --format script manila -e kolla_action=upgrade 2>&1)

osism wait --output --format script --delay 2 $task_ids
