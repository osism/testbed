#!/usr/bin/env bash
set -x
set -e

# check ceph services
sh -c '/opt/configuration/scripts/check/100-ceph-services.sh'
