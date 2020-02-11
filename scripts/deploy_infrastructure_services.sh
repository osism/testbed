#!/usr/bin/env bash

export INTERACTIVE=false

osism-infrastructure helper --tags phpmyadmin
osism-infrastructure helper --tags openstackclient

osism-kolla deploy common
osism-kolla deploy openvswitch
osism-kolla deploy memcached
osism-kolla deploy redis
osism-kolla deploy haproxy
osism-kolla deploy elasticsearch
osism-kolla deploy kibana
osism-kolla deploy etcd

# NOTE: workaround "Index .kibana belongs to a version of Kibana that cannot be
#       automatically migrated. Reset it or use the X-Pack upgrade assistant."
curl -X DELETE http://192.168.50.200:9200/.kibana

osism-kolla deploy rabbitmq
osism-kolla deploy mariadb
