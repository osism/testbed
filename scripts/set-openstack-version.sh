#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-yoga}

if [[ $(grep "^openstack_version:" /opt/configuration/environments/manager/configuration.yml) ]]; then
    sed -i "s/openstack_version: .*/openstack_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
else
    sed -i -e '/manager_version: .*/a\' -e "openstack_version: ${VERSION}" /opt/configuration/environments/manager/configuration.yml
fi
