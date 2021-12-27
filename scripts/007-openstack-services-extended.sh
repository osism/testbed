#!/usr/bin/env bash

export INTERACTIVE=false

osism apply gnocchi
osism apply ceilometer
osism apply aodh
osism apply panko

osism apply senlin
