#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply gnocchi -e kolla_action=upgrade
osism apply ceilometer -e kolla_action=upgrade
osism apply heat -e kolla_action=upgrade
osism apply senlin -e kolla_action=upgrade
