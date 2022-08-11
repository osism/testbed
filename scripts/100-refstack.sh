#!/usr/bin/env bash

pushd /opt/configuration/contrib/refstack

/opt/configuration/contrib/refstack/prepare.sh
/opt/configuration/contrib/refstack/test.sh

popd
