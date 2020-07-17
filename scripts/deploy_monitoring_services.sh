#!/usr/bin/env bash

export INTERACTIVE=false

osism-generic zabbix-agent
osism-infrastructure netdata
osism-kolla deploy prometheus
