#!/usr/bin/env bash

export INTERACTIVE=false

# deploy basic OpenStack services

osism-kolla deploy keystone
osism-kolla deploy horizon
osism-kolla deploy placement
osism-kolla deploy glance
osism-kolla deploy cinder
osism-kolla deploy neutron
osism-kolla deploy nova

osism-custom run bootstrap-basic

# deploy additional OpenStack services

osism-kolla deploy heat
osism-kolla deploy gnocchi
osism-kolla deploy ceilometer
osism-kolla deploy aodh
osism-kolla deploy panko
osism-kolla deploy magnum
osism-kolla deploy barbican
osism-kolla deploy designate

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osisk-kolla deploy skydive
osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
