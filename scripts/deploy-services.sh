#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/000-pull-images.sh'

# deploy helper services
sh -c '/opt/configuration/scripts/001-helper-services.sh'

# only deploy identity services
# NOTE: All necessary infrastructure services are also deployed.
if [[ "$DEPLOY_IDENTITY" == "true" ]]; then
    sh -c '/opt/configuration/scripts/999-identity-services.sh'
else
    sh -c '/opt/configuration/scripts/002-infrastructure-services-basic.sh'
    sh -c '/opt/configuration/scripts/003-ceph-services.sh'
    sh -c '/opt/configuration/scripts/004-openstack-services-basic.sh'
    sh -c '/opt/configuration/scripts/009-openstack-services-baremetal.sh'
fi

# deploy monitoring services
if [[ "$DEPLOY_MONITORING" == "true" ]]; then
    sh -c '/opt/configuration/scripts/005-monitoring-services.sh'
fi
