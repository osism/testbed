#!/usr/bin/env bash

refstack-client upload \
    $1 \
    --url https://refstack.openstack.org/api \
    -i ~/.ssh/id_rsa.refstack
