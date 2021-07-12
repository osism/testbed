#!/usr/bin/env bash

DEFAULT_VERSION=pacific
VERSION=${1:-pacific}

grep -rlZ $DEFAULT_VERSION * | xargs -0 sed -i "s/${DEFAULT_VERSION}/${VERSION}/g"
