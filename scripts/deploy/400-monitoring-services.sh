#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script netdata 2>&1)
task_ids+=" "$(osism apply --no-wait --format script prometheus 2>&1)
task_ids+=" "$(osism apply --no-wait --format script grafana 2>&1)

osism wait --output --format script --delay 2 $task_ids
