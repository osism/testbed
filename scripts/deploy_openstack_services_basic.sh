#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy testbed --tags openstack

osism-run openstack bootstrap-octavia-pre
osism-kolla deploy octavia
osism-run openstack bootstrap-octavia-post

osism-run openstack bootstrap-basic
osism-run openstack bootstrap-ceph-rgw
