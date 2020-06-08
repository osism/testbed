#!/usr/bin/env bash

DEFAULT_VERSION=train
VERSION=${1:-train}

grep -rlZ "$DEFAULT_VERSION" * | xargs -0 sed -i "/constraint/! s/${DEFAULT_VERSION}/${VERSION}/g"
