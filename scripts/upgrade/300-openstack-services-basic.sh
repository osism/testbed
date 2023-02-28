#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply keystone -e kolla_action=upgrade
osism apply placement -e kolla_action=upgrade
osism apply nova -e kolla_action=upgrade

osism apply horizon -e kolla_action=upgrade
osism apply glance -e kolla_action=upgrade
osism apply neutron -e kolla_action=upgrade
osism apply cinder -e kolla_action=upgrade
osism apply barbican -e kolla_action=upgrade
osism apply designate -e kolla_action=upgrade
osism apply octavia -e kolla_action=upgrade
