#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags sshconfig
osism-run custom generate-ssh-known-hosts
