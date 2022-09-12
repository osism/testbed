#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

OPENSTACK_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)

curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-${OPENSTACK_VERSION}.kernel -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel
curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-${OPENSTACK_VERSION}.initramfs -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs

osism apply ironic -e kolla_action=upgrade
