#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy gnocchi
osism-kolla deploy ceilometer
osism-kolla deploy aodh
osism-kolla deploy panko

osism-kolla deploy heat
osism-kolla deploy barbican
osism-kolla deploy senlin

osism-kolla deploy magnum
osism-run openstack bootstrap-magnum
