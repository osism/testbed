#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

echo
echo "# Refstack"
echo

osism validate refstack
/opt/refstack/test.sh
