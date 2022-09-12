#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-yoga}

sed -i "s/openstack_version: .*/openstack_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
