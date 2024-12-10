#!/usr/bin/env bash
set -x
set -e

echo
echo "# Checking for active prometheus alerts"
echo

osism apply prometheus-alert-status
