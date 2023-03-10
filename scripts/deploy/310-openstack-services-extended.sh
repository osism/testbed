#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply gnocchi

task_ids=$(osism apply --no-wait --format script ceilometer2>&1)
task_ids+=" "$(osism apply --no-wait --format script heat 2>&1)
task_ids+=" "$(osism apply --no-wait --format script senlin 2>&1)

osism wait --output --format script --delay 2 $task_ids
