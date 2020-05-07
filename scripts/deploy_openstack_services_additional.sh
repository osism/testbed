#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy heat
osism-kolla deploy gnocchi
osism-kolla deploy ceilometer
osism-kolla deploy aodh
osism-kolla deploy panko
osism-kolla deploy barbican
osism-kolla deploy designate
osism-kolla deploy manila

osism-kolla deploy influxdb
osism-kolla deploy cloudkitty

osism-kolla deploy magnum
osism-run openstack bootstrap-magnum

osism-run openstack bootstrap-octavia
osism-kolla deploy octavia

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osism-kolla deploy skydive
osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
