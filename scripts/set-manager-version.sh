#!/usr/bin/env bash
set -x
set -e

VERSION=${1:-latest}

sed -i "s/manager_version: .*/manager_version: ${VERSION}/g" /opt/configuration/environments/manager/configuration.yml
