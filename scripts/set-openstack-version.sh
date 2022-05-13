#!/usr/bin/env bash

DEFAULT_VERSION=xena
VERSION=${1:-xena}

sed -i "s/openstack_version: ${DEFAULT_VERSION}/openstack_version: ${VERSION}/g" environments/manager/configuration.yml
