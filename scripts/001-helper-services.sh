#!/usr/bin/env bash

export INTERACTIVE=false

osism apply sshconfig
osism-run custom generate-ssh-known-hosts
osism apply dotfiles
