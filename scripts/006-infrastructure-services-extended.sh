#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply patchman
osism apply patchman-client -- -e patchman_client_update_force=true

# NOTE: After all clients have transferred their data with the
#       previous call, the evaluation of this data is now triggered.
#
#       In the future, this will no longer be necessary. The
#       patchman-client will then trigger the necessary update on
#       its own.

osism apply patchman -- -e patchman_update_force=true

osism apply nexus
