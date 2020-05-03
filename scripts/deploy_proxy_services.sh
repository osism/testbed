#!/usr/bin/env bash

export INTERACTIVE=false

osism-run custom proxy
osism-run custom registry-proxy
osism-generic proxy
