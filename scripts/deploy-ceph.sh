#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY CEPH SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# deploy ceph services
deploy_ceph
