#!/usr/bin/env bash

export INTERACTIVE=false

osism netdata
osism apply prometheus
osism apply grafana
