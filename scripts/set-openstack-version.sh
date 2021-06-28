#!/usr/bin/env bash

DEFAULT_VERSION=wallaby
VERSION=${1:-wallaby}

grep -rlZ "$DEFAULT_VERSION" * | xargs -0 sed -i "/constraint/! s/${DEFAULT_VERSION}/${VERSION}/g"
