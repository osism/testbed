#!/usr/bin/env bash

export INTERACTIVE=false

osism apply netdata
osism apply prometheus
osism apply grafana
