#!/usr/bin/env bash
set -e

export INTERACTIVE=false

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-${OPENSTACK_VERSION}.kernel -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel
curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-${OPENSTACK_VERSION}.initramfs -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs

# NOTE: The docker-compose role is currently required for the
#       virtualbmc service. Can be removed again when everything
#       has been switched to the docker compose cli plugin.
osism apply docker-compose

osism apply virtualbmc
osism apply ironic
