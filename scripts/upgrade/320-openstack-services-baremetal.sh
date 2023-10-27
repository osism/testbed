#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply -a upgrade ironic -e enable_ironic_agent_download_images=true
