#!/usr/bin/env bash

source /opt/refstack/client/.venv/bin/activate
/opt/refstack/client/refstack-client test -c /opt/configuration/contrib/refstack/tempest.conf -v -r osism -- --regex $1
