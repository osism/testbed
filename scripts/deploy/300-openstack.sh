#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

osism apply keystone
osism apply placement
osism apply neutron
osism apply nova

osism apply horizon
osism apply skyline
osism apply glance
osism apply cinder
osism apply barbican
osism apply designate
osism apply octavia
osism apply ceilometer
osism apply aodh

osism apply kolla-ceph-rgw
