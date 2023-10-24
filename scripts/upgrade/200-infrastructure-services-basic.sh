#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

osism apply -a upgrade common
osism apply -a upgrade loadbalancer

task_ids=$(osism apply --no-wait --format script openstackclient 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade opensearch 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade memcached 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade redis 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade mariadb 2>&1)
task_ids+=" "$(osism apply --no-wait --format script -a upgrade rabbitmq 2>&1)

osism wait --output --format script --delay 2 $task_ids

osism apply -a upgrade openvswitch
osism apply -a upgrade ovn
