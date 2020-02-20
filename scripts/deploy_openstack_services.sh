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
osisk-kolla deploy skydive
osism-kolla deploy magnum
