#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY CEPH SERVICES"
echo

source /opt/manager-vars.sh

export INTERACTIVE=false

sh -c '/opt/configuration/scripts/deploy/100-ceph-services-basic.sh'
