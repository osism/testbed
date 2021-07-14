#!/usr/bin/env bash

DEFAULT_VERSION=wallaby
VERSION=${1:-wallaby}

sed -i "s/openstack_version: ${DEFAULT_VERSION}/openstack_version: ${VERSION}/g" environments/manager/configuration.yml
