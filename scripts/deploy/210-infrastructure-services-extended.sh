#!/usr/bin/env bash
set -e

export INTERACTIVE=false

task_ids=$(osism apply --no-wait --format script patchman 2>&1)
task_ids+=" "$(osism apply --no-wait --format script nexus 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism apply patchman-client -- -e patchman_client_update_force=true

# NOTE: After all clients have transferred their data with the
#       previous call, the evaluation of this data is now triggered.
#
#       In the future, this will no longer be necessary. The
#       patchman-client will then trigger the necessary update on
#       its own.

osism apply patchman -- -e patchman_update_force=true
