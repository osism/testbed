#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply influxdb

osism apply manila
