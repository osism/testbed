#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

echo
echo "# Refstack"
echo

osism validate refstack
/opt/refstack/test.sh
