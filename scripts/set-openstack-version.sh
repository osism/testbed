#!/usr/bin/env bash

DEFAULT_VERSION=ussuri
VERSION=${1:-ussuri}

grep -rlZ "$DEFAULT_VERSION" * | xargs -0 sed -i "/constraint/! s/${DEFAULT_VERSION}/${VERSION}/g"
