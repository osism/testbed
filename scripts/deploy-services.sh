#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# pull images
sh -c '/opt/configuration/scripts/000-pull-images.sh'

# deploy helper services
sh -c '/opt/configuration/scripts/deploy/001-helper-services.sh'

# only deploy identity services
# NOTE: All necessary infrastructure services are also deployed.
if [[ "$DEPLOY_IDENTITY" == "true" ]]; then
    sh -c '/opt/configuration/scripts/999-identity-services.sh'
else
    sh -c '/opt/configuration/scripts/deploy/100-ceph-services-basic.sh'
    sh -c '/opt/configuration/scripts/deploy/110-ceph-services-extended.sh'
    sh -c '/opt/configuration/scripts/deploy/200-infrastructure-services-basic.sh'
    sh -c '/opt/configuration/scripts/deploy/300-openstack-services-basic.sh'
    sh -c '/opt/configuration/scripts/deploy/320-openstack-services-baremetal.sh'
fi

# deploy monitoring services
if [[ "$DEPLOY_MONITORING" == "true" ]]; then
    sh -c '/opt/configuration/scripts/deploy/400-monitoring-services.sh'
fi
