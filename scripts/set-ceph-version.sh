#!/usr/bin/env bash

DEFAULT_VERSION=pacific
VERSION=${1:-pacific}

sed -i "s/ceph_version: ${DEFAULT_VERSION}/ceph_version: ${VERSION}/g" environments/manager/configuration.yml
