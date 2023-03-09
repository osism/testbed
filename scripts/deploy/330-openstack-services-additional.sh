#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids+=" "$(osism apply --no-wait --format script aodh 2>&1)
task_ids+=" "$(osism apply --no-wait --format script manila 2>&1)

osism wait --output --format script --delay 2 $task_ids
