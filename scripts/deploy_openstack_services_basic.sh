#!/usr/bin/env bash

export INTERACTIVE=false

# deploy basic OpenStack services

osism-kolla deploy keystone
osism-kolla deploy horizon
osism-kolla deploy placement
osism-kolla deploy glance
osism-kolla deploy cinder
osism-kolla deploy neutron
osism-kolla deploy nova

osism-run openstack bootstrap-basic
