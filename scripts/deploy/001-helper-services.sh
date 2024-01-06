#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply --no-wait cgit
osism apply --no-wait dotfiles
osism apply --no-wait homer
osism apply --no-wait phpmyadmin
osism apply --no-wait sosreport
