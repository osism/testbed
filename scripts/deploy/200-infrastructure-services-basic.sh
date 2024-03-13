#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack" }}' kolla-ansible)

osism apply common
osism apply loadbalancer
osism apply openstackclient
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply openvswitch
osism apply ovn

# In OSISM >= 5.0.0, the switch was made from Elasticsearch / Kibana to Opensearch.
if [[ $MANAGER_VERSION =~ ^4\.[0-9]\.[0-9]$ || $OPENSTACK_VERSION == "yoga" ]]; then
    osism apply elasticsearch
    if [[ "$REFSTACK" == "false" ]]; then
        osism apply kibana
    fi
else
    osism apply opensearch
fi

# In OSISM >= 7.0.0, the Keycloak deployment (technical preview) was switched from
# Docker Compose to Kubernetes.
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply keycloak
    osism apply keycloak-oidc-client-config
    sed -i "s/enable_keystone_federation: \"no\"/enable_keystone_federation: \"yes\"/" /opt/configuration/environments/kolla/configuration.yml
fi
