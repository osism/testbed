#!/usr/bin/env bash

export INTERACTIVE=false

osism apply openstackclient
osism apply keycloak
osism-run custom keycloak-oidc-client-config
osism apply common
osism apply haproxy
osism apply elasticsearch
osism apply openvswitch
osism apply memcached
osism apply redis
osism apply etcd
osism apply mariadb
osism apply kibana
osism apply ovn
osism apply rabbitmq
osism apply homer
