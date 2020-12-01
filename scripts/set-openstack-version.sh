#!/usr/bin/env bash

DEFAULT_VERSION=victoria
VERSION=${1:-victoria}

grep -rlZ "$DEFAULT_VERSION" * | xargs -0 sed -i "/constraint/! s/${DEFAULT_VERSION}/${VERSION}/g"
