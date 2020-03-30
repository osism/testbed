#!/usr/bin/env bash

DEFAULT_VERSION=nautilus
VERSION=${1:-nautilus}

grep -rlZ $DEFAULT_VERSION * | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
