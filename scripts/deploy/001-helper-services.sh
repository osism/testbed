#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script sshconfig 2>&1)
task_ids+=" "$(osism apply --no-wait --format script known-hosts 2>&1)
task_ids+=" "$(osism apply --no-wait --format script dotfiles 2>&1)
task_ids+=" "$(osism apply --no-wait --format script cgit 2>&1)
task_ids+=" "$(osism apply --no-wait --format script squid 2>&1)

osism wait --output --format script --delay 2 $task_ids
