#!/usr/bin/env bash

DEFAULT_VERSION=yoga
VERSION=${1:-yoga}

sed -i "s/openstack_version: ${DEFAULT_VERSION}/openstack_version: ${VERSION}/g" environments/manager/configuration.yml
