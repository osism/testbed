#!/usr/bin/env bash

export INTERACTIVE=false

curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-xena.kernel -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel
curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-xena.initramfs -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs

# NOTE: The docker-compose role is currently required for the
#       virtualbmc service. Can be removed again when everything
#       has been switched to the docker compose cli plugin.
osism apply docker-compose

osism apply virtualbmc
osism apply ironic
