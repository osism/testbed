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

sed -i "s/enable_keystone_federation: \"no\"/enable_keystone_federation: \"yes\"/" /opt/configuration/environments/kolla/configuration.yml
sed -i "s/keystone_enable_federation_openid: \"no\"/keystone_enable_federation_openid: \"yes\"/" /opt/configuration/environments/kolla/configuration.yml

osism apply common
osism apply loadbalancer
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon

osism apply homer
