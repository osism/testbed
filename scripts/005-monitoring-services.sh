#!/usr/bin/env bash

export INTERACTIVE=false

osism-monitoring netdata
osism-kolla deploy prometheus
