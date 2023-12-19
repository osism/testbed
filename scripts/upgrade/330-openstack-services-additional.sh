#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply -a upgrade aodh
osism apply -a upgrade manila
