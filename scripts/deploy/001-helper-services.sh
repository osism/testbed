#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply --no-wait cgit
osism apply --no-wait squid
