#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY IDENTITY SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

osism apply openstackclient

# In OSISM >= 7.0.0, the Keycloak deployment (technical preview) was switched from
# Docker Compose to Kubernetes.
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply kubernetes
    osism apply keycloak
    osism apply keycloak-oidc-client-config
    sed -i "s/enable_keystone_federation: \"no\"/enable_keystone_federation: \"yes\"/" /opt/configuration/environments/kolla/configuration.yml
fi

osism apply common
osism apply loadbalancer
osism apply memcached
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon

osism apply homer
