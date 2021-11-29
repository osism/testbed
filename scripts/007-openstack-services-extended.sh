#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy gnocchi
osism-kolla deploy ceilometer
osism-kolla deploy aodh
osism-kolla deploy panko

osism-kolla deploy senlin
