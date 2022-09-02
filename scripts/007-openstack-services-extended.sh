#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply gnocchi
osism apply ceilometer
osism apply aodh

osism apply senlin
