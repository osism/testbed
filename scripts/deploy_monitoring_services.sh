#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure netdata
osism-kolla deploy prometheus
