#!/usr/bin/env bash
set -x
set -e

# pull images
sh -c '/opt/configuration/scripts/000-pull-images.sh'

# upgrade ceph services
sh -c '/opt/configuration/scripts/upgrade/100-ceph-services.sh'

# upgrade infrastructure services
sh -c '/opt/configuration/scripts/upgrade/200-infrastructure-services-basic.sh'

# upgrade openstack services
sh -c '/opt/configuration/scripts/upgrade/300-openstack-services-basic.sh'
sh -c '/opt/configuration/scripts/upgrade/320-openstack-services-baremetal.sh'
