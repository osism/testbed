#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

# check ceph services
sh -c '/opt/configuration/scripts/check/100-ceph-with-ansible.sh'

# check that the dedicated cephadm SSH key is scoped to the ceph group
sh -c '/opt/configuration/scripts/check/101-ceph-ssh-key-scope.sh'
