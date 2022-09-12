#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply influxdb

osism apply manila

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osism apply skydive
osism apply --environment generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
