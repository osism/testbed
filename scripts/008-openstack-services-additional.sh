#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy influxdb

osism-kolla deploy kuryr
osism-kolla deploy manila
osism-kolla deploy zun

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osism-kolla deploy skydive
osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
