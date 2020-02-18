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

# NOTE: The Skydive agent creates a high load on the Open vSwitch services.
#       Therefore the agent is only started manually when needed.

osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent

# NOTE: workaround "Index .kibana belongs to a version of Kibana that cannot be
#       automatically migrated. Reset it or use the X-Pack upgrade assistant."
curl -X DELETE http://192.168.50.200:9200/.kibana

osism-kolla deploy rabbitmq
osism-kolla deploy mariadb
