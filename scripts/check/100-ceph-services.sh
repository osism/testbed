#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

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

# The 'osism validate' command is only available since 5.0.0.
if [[ $(semver $MANAGER_VERSION 5.0.0) -eq -1 ]]; then
    echo "ceph validate not possible with OSISM 4"
else
    # The Ceph validate plays are only usable with Docker at the moment.
    # On CentOS we use Podman for the Ceph deployment and cannot use the
    # Ceph validate plays at the moment.
    if [[ ! -e /etc/redhat-release ]]; then
        osism apply facts
        osism validate ceph-mons
        osism validate ceph-mgrs
        osism validate ceph-osds
    fi
fi
