#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-latest}

sed -i "s/manager_version: .*/manager_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml

if [[ $VERSION != "latest" ]]; then
    # In a stable release, the versions of Ceph and OpenStack to use
    # are set by the version of the stable release (set via the
    # manager_version parameter) and not by release names.
    sed -i "/ceph_version:/d" /opt/configuration/environments/manager/configuration.yml
    sed -i "/openstack_version:/d" /opt/configuration/environments/manager/configuration.yml

fi

# Sync testbed repo with generics
pushd /opt/configuration
pip3 install --no-cache-dir python-gilt==1.2.3
export PATH=$PATH:/home/dragon/.local/bin
GILT=$(which gilt)
${GILT} overlay
${GILT} overlay
popd
