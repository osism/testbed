#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure sshconfig
osism-run custom generate-ssh-known-hosts
osism-generic dotfiles
osism-infrastructure homer
