#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

# Do not use the Keystone/Keycloak integration by default. We only use this integration
# in a special identity testbed.
rm -f /opt/configuration/environments/kolla/group_vars/keystone.yml
rm -f /opt/configuration/environments/kolla/files/overlays/keystone/wsgi-keystone.conf
rm -rf /opt/configuration/environments/kolla/files/overlays/keystone/federation

osism apply -a upgrade keystone
osism apply -a upgrade placement
osism apply -a upgrade neutron
osism apply -a upgrade nova
osism apply -a upgrade horizon
osism apply -a upgrade glance
osism apply -a upgrade cinder
osism apply -a upgrade barbican
osism apply -a upgrade designate

# In OSISM >= 7.0.0 the persistence feature in Octavia was enabled by default.
# This requires an additional database, which is only created when Octavia play
# is run in bootstrap mode first.
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    osism apply -a bootstrap octavia
fi

osism apply -a upgrade octavia

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    # In the testbed, the service was only added with OSISM 7.0.0. It is therefore necessary
    # to check in advance whether the service is already available. If not, a deployment must
    # be carried out instead of an upgrade.

    if [[ -z $(openstack --os-cloud admin service list -f value -c Name | grep magnum) ]]; then
        osism apply magnum
    else
        osism apply -a upgrade magnum
    fi
fi
