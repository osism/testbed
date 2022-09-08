#!/usr/bin/env bash
set -x
set -e

# check ceph services
sh -c '/opt/configuration/scripts/check/100-ceph-services.sh'

# check infrastructure services
sh -c '/opt/configuration/scripts/check/200-infrastructure-services.sh'

# check openstack services
sh -c '/opt/configuration/scripts/check/300-openstack-services.sh'
