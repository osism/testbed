#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply -a upgrade ironic
