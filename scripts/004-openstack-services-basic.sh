#!/usr/bin/env bash

export INTERACTIVE=false

osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply cinder
osism apply neutron
osism apply nova

osism apply barbican
osism apply designate
osism apply heat
osism apply octavia

osism-run openstack bootstrap-basic
osism-run openstack bootstrap-ceph-rgw

osism-monitoring openstack-health-monitor
