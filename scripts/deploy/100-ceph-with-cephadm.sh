#!/usr/bin/env bash
#
# Deploy Ceph with cephadm instead of ceph-ansible.
#
# The whole cluster -- bootstrap, host registration, configuration, the MON, MGR
# and crash daemons, the OSDs, the pools and their keys, CephFS with its MDS
# daemons, RGW and the dashboard -- is deployed by the cephadm plays, this script
# only sequences them.
#
# The preparation of the OSD devices is done with
# scripts/prepare-ceph-configuration.sh, i.e. with the configure-lvm-volumes and
# create-lvm-devices plays. The LVM volumes created there are handed over to
# cephadm as explicit LVM paths, cephadm does not touch the raw block devices
# itself.
#
# The Ceph image and release are not selected here, the plays take them from
# the inventory (ceph_docker_registry, ceph_docker_image and
# ceph_docker_image_tag).
set -e
set -o pipefail

source /opt/configuration/scripts/include.sh

echo
echo "# DEPLOY CEPH SERVICES WITH CEPHADM"
echo

##########################################################
# prepare the OSD devices

echo
echo "## Prepare the Ceph configuration"
echo

sh -c '/opt/configuration/scripts/prepare-ceph-configuration.sh'

##########################################################
# deploy the core cluster

echo
echo "## Deploy the core cluster"
echo

# cephadm-bootstrap installs cephadm on the Ceph hosts and bootstraps the
# cluster with the dedicated Ceph key from /opt/ansible/secrets/id_rsa.ceph
# (environments/secrets.yml, inventory/group_vars/ceph.yml). cephclient follows
# immediately, the remaining plays drive the orchestrator through it.
osism apply cephadm-bootstrap
osism apply cephclient
osism apply cephadm-hosts
osism apply cephadm-config
osism apply cephadm-mons
osism apply cephadm-osds
osism apply cephadm-pools
osism apply copy-ceph-keys
osism apply cephadm-mds
osism apply cephadm-rgw
osism apply cephadm-dashboard

##########################################################
# summary

echo
echo "## Summary"
echo

ceph -s
ceph versions
ceph orch ls
ceph orch ps
