#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply ironic -e enable_ironic_agent_download_images=true
