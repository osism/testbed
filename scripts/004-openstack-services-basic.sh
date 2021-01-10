#!/usr/bin/env bash

export INTERACTIVE=false

osism-kolla deploy testbed --tags openstack --skip-tags infrastructure

osism-run openstack bootstrap-octavia-pre
osism-kolla deploy octavia
osism-run openstack bootstrap-octavia-post

osism-kolla deploy barbican
osism-kolla deploy designate

osism-run openstack bootstrap-basic
osism-run openstack bootstrap-ceph-rgw
