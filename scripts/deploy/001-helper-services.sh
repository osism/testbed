#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply cgit
osism apply dotfiles
osism apply sosreport
osism apply squid
