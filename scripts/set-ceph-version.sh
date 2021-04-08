#!/usr/bin/env bash

DEFAULT_VERSION=octopus
VERSION=${1:-octopus}

grep -rlZ $DEFAULT_VERSION * | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
