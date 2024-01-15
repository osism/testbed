#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

echo
echo "# Ceph status"
echo

ceph -s

echo
echo "# Ceph versions"
echo

ceph versions

echo
echo "# Ceph OSD tree"
echo

ceph osd df tree

echo
echo "# Ceph monitor status"
echo

ceph mon stat

echo
echo "# Ceph quorum status"
echo

< /dev/null ceph quorum_status | jq

echo
echo "# Ceph free space status"
echo

ceph df

# osism validate is only available since 5.0.0. To enable the
# testbed to be used with < 5.0.0, here is this check.
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ ]]; then
    echo "ceph validate not possible with OSISM 4"
else
    osism apply facts
    osism validate ceph-mons
    osism validate ceph-mgrs
    osism validate ceph-osds
fi
