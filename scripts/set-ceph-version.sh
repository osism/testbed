#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-pacific}

if [[ $(grep "^ceph_version:" /opt/configuration/environments/manager/configuration.yml) ]]; then
    sed -i "s/ceph_version: .*/ceph_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
else
    sed -i -e '/manager_version: .*/a\' -e "ceph_version: ${VERSION}" /opt/configuration/environments/manager/configuration.yml
fi
