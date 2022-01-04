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

osism apply --environment openstack bootstrap-basic
osism apply --environment openstack bootstrap-ceph-rgw

osism apply openstack-health-monitor
