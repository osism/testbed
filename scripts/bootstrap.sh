#!/usr/bin/env bash
set -x
set -e

echo
echo "# BOOTSTRAP"
echo

# bootstrap services
sh -c '/opt/configuration/scripts/bootstrap-services.sh'
