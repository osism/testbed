#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure phpmyadmin

osism-infrastructure patchman
osism-generic patchman-client -e patchman_client_update_force=true

# NOTE: After all clients have transferred their data with the
#       previous call, the evaluation of this data is now triggered.
#
#       In the future, this will no longer be necessary. The
#       patchman-client will then trigger the necessary update on
#       its own.

osism-infrastructure patchman -e patchman_update_force=true
