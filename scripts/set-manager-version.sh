#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-latest}

sed -i "s/manager_version: .*/manager_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml


# NOTE: For a stable release, the versions of Ceph and OpenStack to use
#       are set by the version of the stable release (set via the
#       manager_version parameter) and not by release names.

if [[ $VERSION != "latest" ]]; then
    sed -i "/ceph_version:/d" /opt/configuration/environments/manager/configuration.yml
    sed -i "/openstack_version:/d" /opt/configuration/environments/manager/configuration.yml
fi
