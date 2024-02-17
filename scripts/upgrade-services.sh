#!/usr/bin/env bash
set -x
set -e

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# upgrade infrastructure services
sh -c '/opt/configuration/scripts/upgrade/200-infrastructure-services-basic.sh'

# upgrade ceph services
sh -c '/opt/configuration/scripts/upgrade/100-ceph-services.sh'

# upgrade openstack services
sh -c '/opt/configuration/scripts/upgrade/300-openstack-services-basic.sh'
sh -c '/opt/configuration/scripts/upgrade/310-openstack-services-extended.sh'
sh -c '/opt/configuration/scripts/upgrade/320-openstack-services-baremetal.sh'

# upgrade monitoring services
sh -c '/opt/configuration/scripts/upgrade/400-monitoring-services.sh'
