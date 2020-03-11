#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure helper --tags openstackclient
osism-infrastructure netdata
osism-generic cockpit

osism-kolla deploy common
osism-kolla deploy openvswitch
osism-kolla deploy memcached
osism-kolla deploy redis
osism-kolla deploy haproxy
osism-kolla deploy elasticsearch
osism-kolla deploy kibana
osism-kolla deploy etcd
osism-kolla deploy rabbitmq
osism-kolla deploy mariadb
