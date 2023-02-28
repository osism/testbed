#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply aodh
osism apply heat
osism apply manila
