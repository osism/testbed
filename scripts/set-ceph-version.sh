#!/usr/bin/env bash

DEFAULT_VERSION=luminous
VERSION=${1:-luminous}

grep -rlZ $DEFAULT_VERSION * | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
