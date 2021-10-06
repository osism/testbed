#!/usr/bin/env bash

source /opt/refstack/client/.venv/bin/activate
refstack-client upload \
    $1 \
    --url https://refstack.openstack.org/api \
    -i ~/.ssh/id_rsa.refstack
