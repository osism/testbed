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
