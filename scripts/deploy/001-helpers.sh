#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

osism apply --no-wait cgit
osism apply --no-wait dotfiles
osism apply --no-wait homer
osism apply --no-wait phpmyadmin
osism apply --no-wait sosreport
