#!/usr/bin/env bash

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf --test-list /opt/refstack/test-list.txt -v -r osism
