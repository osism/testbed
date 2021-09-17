#!/usr/bin/env bash

export INTERACTIVE=false

curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-wallaby.kernel -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel
curl https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos8-stable-wallaby.initramfs -o /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs

osism-infrastructure virtualbmc
osism-kolla deploy ironic
