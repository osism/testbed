#!/usr/bin/env bash

export INTERACTIVE=false

osism-manager sshconfig
osism-run custom generate-ssh-known-hosts
osism-run custom wireguard
osism-generic dotfiles
