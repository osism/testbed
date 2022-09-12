#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

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
