#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-reef}

# A numbered release keeps release names out of the manager configuration
# (see set-manager-version.sh), so only the latest track gets one there.
if grep -q '^manager_version: latest' /opt/configuration/environments/manager/configuration.yml; then
    if [[ "$(grep '^ceph_version:' /opt/configuration/environments/manager/configuration.yml)" ]]; then
        sed -i "s/ceph_version: .*/ceph_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
    else
        sed -i -e '/manager_version: .*/a\' -e "ceph_version: ${VERSION}" /opt/configuration/environments/manager/configuration.yml
    fi
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

# ceph-ansible has no branch past squid. For any later Ceph release the manager
# runs no ceph-ansible container -- there is no image for it -- and options the
# release removed are dropped from the Ceph configuration: Tentacle removed
# "rgw keystone api version" together with Keystone v2.0 support, and writing a
# removed option fails the cephadm configuration play. Earlier releases still
# default it to 2, so it stays for them.
case $VERSION in
    quincy|reef|squid)
        ;;
    *)
        if ! grep -q '^ceph_ansible_enable:' /opt/configuration/environments/manager/configuration.yml; then
            echo "ceph_ansible_enable: false" >> /opt/configuration/environments/manager/configuration.yml
        fi
        for file in /opt/configuration/environments/ceph*/configuration.yml; do
            sed -i '/"rgw keystone api version":/d' "$file"
        done
        ;;
esac
