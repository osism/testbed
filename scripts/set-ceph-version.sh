#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-pacific}

sed -i "s/ceph_version: .*/ceph_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
