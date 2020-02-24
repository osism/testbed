#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy keystone
osism-kolla deploy horizon
osism-kolla deploy placement
osism-kolla deploy glance
osism-kolla deploy cinder
osism-kolla deploy neutron
osism-kolla deploy nova
osism-kolla deploy heat
osism-kolla deploy gnocchi
osism-kolla deploy ceilometer
osism-kolla deploy aodh
osism-kolla deploy panko
osism-kolla deploy magnum

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osisk-kolla deploy skydive
osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
