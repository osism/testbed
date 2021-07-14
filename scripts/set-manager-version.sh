#!/usr/bin/env bash

DEFAULT_VERSION=latest
VERSION=${1:-latest}

sed -i "s/manager_version: ${DEFAULT_VERSION}/manager_version: ${VERSION}/g" environments/manager/configuration.yml
