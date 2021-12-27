#!/usr/bin/env bash

export INTERACTIVE=false

osism apply sshconfig
osism apply known-hosts
osism apply dotfiles
