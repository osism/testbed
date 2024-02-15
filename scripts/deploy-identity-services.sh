#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY IDENTITY SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

osism apply openstackclient

osism apply kubernetes

osism apply keycloak
osism apply keycloak-oidc-client-config

osism apply common
osism apply loadbalancer
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon

osism apply homer
