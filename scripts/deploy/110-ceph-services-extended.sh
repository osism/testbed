#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply ceph-mdss
osism apply ceph-rgws
