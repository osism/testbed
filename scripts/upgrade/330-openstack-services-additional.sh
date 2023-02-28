#!/usr/bin/env bash
set -e

export INTERACTIVE=false

osism apply aodh -e kolla_action=upgrade
osism apply heat -e kolla_action=upgrade
osism apply manila -e kolla_action=upgrade
