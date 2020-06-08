#!/usr/bin/env bash

DEFAULT_VERSION=train
VERSION=${1:-train}

grep -rlZ $DEFAULT_VERSION * | grep -v constraint | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
