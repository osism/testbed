#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

osism apply rook-operator
osism apply rook
osism apply rook-fetch-keys
# osism apply rook-cephclient
