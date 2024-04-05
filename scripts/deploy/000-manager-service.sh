#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
source /opt/configuration/scripts/include.sh

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# For a stable release, the versions of Ceph and OpenStack to use
# are set by the version of the stable release (set via the
# manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
fi

ansible-playbook \
  -i testbed-manager.testbed.osism.xyz, \
  --vault-password-file /opt/configuration/environments/.vault_pass \
  /opt/configuration/ansible/manager-part-3.yml

cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# wait for manager service
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# disable ara service
if [[ -e /etc/osism-ci-image ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# wait for netbox service
if ! wait_for_container_healthy 60 netbox-netbox-1; then
    # The Netbox integration is not mandatory for the use of the testbed.
    # Therefore it is ok to skip if the deployment did not work. A separate
    # job will be created later for the integration tests of the netbox which
    # will then be built into osism/python-osism.
    echo The deployment of the Netbox did not work. Skip the Netbox integration.
else
    osism netbox import
    osism netbox init
    osism netbox manage 1000
    osism netbox connect 1000 --state a

    osism netbox disable --no-wait testbed-switch-0
    osism netbox disable --no-wait testbed-switch-1
    osism netbox disable --no-wait testbed-switch-2
fi

docker compose --project-directory /opt/manager ps
docker compose --project-directory /opt/netbox ps

# use osism.commons.still_alive stdout callback
if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    # The plugin is available in OSISM >= 7.0.0 and higher. In future, the callback
    # plugin will be used by default.
    sed -i "s/community.general.yaml/osism.commons.still_alive/" /opt/configuration/environments/ansible.cfg
fi

osism apply sshconfig
osism apply known-hosts

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]?$ || $MANAGER_VERSION == "latest" ]]; then
    # The Nexus service is only really operational again from OSISM 6.1.0.
    osism apply nexus

    if [[ -e /etc/osism-ci-image ]]; then
        sh -c '/opt/configuration/scripts/set-docker-registry.sh nexus.testbed.osism.xyz:8193'
	sed -i "s/docker_namespace: osism/docker_namespace: kolla/" /opt/configuration/environments/kolla/configuration.yml
    else
        sh -c '/opt/configuration/scripts/set-docker-registry.sh nexus.testbed.osism.xyz:8192'
    fi
fi

osism apply squid

# Ensure that the squid service is up and running.
# This is also added to the osism.services.squid role.
docker compose --project-directory /opt/squid up -d
