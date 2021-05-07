#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure sshconfig
osism-run custom generate-ssh-known-hosts
osism-run custom wireguard
osism-generic dotfiles
osism-infrastructure heimdall
