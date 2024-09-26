#!/usr/bin/env bash
set -x
set -e

osism netbox import
osism netbox init
osism netbox manage 1000
osism netbox connect 1000 --state a

osism netbox disable --no-wait testbed-switch-0
osism netbox disable --no-wait testbed-switch-1
osism netbox disable --no-wait testbed-switch-2
