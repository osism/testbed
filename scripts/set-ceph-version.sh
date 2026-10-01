#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-reef}

if [[ "$(grep '^ceph_version:' /opt/configuration/environments/manager/configuration.yml)" ]]; then
    sed -i "s/ceph_version: .*/ceph_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
else
    sed -i -e '/manager_version: .*/a\' -e "ceph_version: ${VERSION}" /opt/configuration/environments/manager/configuration.yml
fi

# Every environment needs the selected release, not only the manager: without
# a ceph-ansible container, which carried it for the release its image tag
# named, cephclient_version and ceph_image_version fall back to ceph_version.
# environments/configuration.yml is loaded by the plays of every environment.
if [[ "$(grep '^ceph_version:' /opt/configuration/environments/configuration.yml)" ]]; then
    sed -i "s/^ceph_version: .*/ceph_version: ${VERSION}/" /opt/configuration/environments/configuration.yml
else
    sed -i -e '/^ceph_cluster_fsid: .*/a\' -e "ceph_version: ${VERSION}" /opt/configuration/environments/configuration.yml
fi
