#!/usr/bin/env bash

export INTERACTIVE=false

# deploy basic OpenStack services

osism-kolla deploy testbed --tags openstack
osism-run openstack bootstrap-basic
