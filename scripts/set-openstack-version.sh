#!/usr/bin/env bash

DEFAULT_VERSION=rocky
VERSION=${1:-rocky}

grep -rlZ $DEFAULT_VERSION * | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
