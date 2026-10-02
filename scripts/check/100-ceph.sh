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
if [[ $(semver $MANAGER_VERSION 5.0.0) -eq -1 && $MANAGER_VERSION != "latest" ]]; then
    echo "osism validate ceph-* not possible with OSISM < 5.0.0"
else
    osism apply facts
    osism validate ceph-mons
    osism validate ceph-mgrs
    osism validate ceph-osds
fi

# Under cephadm the orchestrator holds state that has no ceph-ansible
# equivalent: which services it is asked to run, and which daemons it has
# placed for them. A service running fewer daemons than its placement asks
# for -- down to none at all -- is the failure a healthy-looking "ceph -s"
# hides, so it fails the check. The backend is read from the cluster rather
# than from CEPH_STACK.
if [[ $(< /dev/null ceph orch status --format json 2>/dev/null | jq -r '.backend // empty') == "cephadm" ]]; then
    echo
    echo "# Ceph orchestrator services"
    echo

    ceph orch ls

    echo
    echo "# Ceph orchestrator daemons"
    echo

    ceph orch ps

    echo
    echo "# Ceph orchestrator hosts"
    echo

    ceph orch host ls

    short=$(< /dev/null ceph orch ls --format json | jq -r '.[]
        | select((.status.size // 0) > 0 and (.status.running // 0) < .status.size)
        | "\(.service_name): \(.status.running // 0) of \(.status.size) running"')
    if [[ -n $short ]]; then
        echo
        echo "Ceph orchestrator services short of daemons:"
        echo "$short"
        exit 1
    fi
fi
