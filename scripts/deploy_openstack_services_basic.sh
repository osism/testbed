#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy testbed --tags openstack

osism-run openstack bootstrap-basic
osism-run openstack bootstrap-ceph-rgw
