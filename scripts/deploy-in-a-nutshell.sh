#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

# prepare the ceph deployment

osism apply --environment custom wipe-partitions
osism apply facts

sed -i "/^devices:/d" /opt/configuration/inventory/group_vars/testbed-nodes.yml
osism apply ceph-configure-lvm-volumes
for node in $(find /opt/configuration/inventory/host_vars -mindepth 1 -type d); do
    if [[ -e /tmp/$(basename $node)-ceph-lvm-configuration.yml ]]; then
        cp /tmp/$(basename $node)-ceph-lvm-configuration.yml /opt/configuration/inventory/host_vars/$(basename $node)/ceph-lvm-configuration.yml
    fi
done
osism reconciler sync
osism apply ceph-create-lvm-devices
osism apply facts

# deploy everything

echo
echo "--> DEPLOY IN A NUTSHELL -- START -- $(date)"
echo

osism apply nutshell

# wait for all deployments

osism wait --output --refresh 20

echo
echo "--> DEPLOY IN A NUTSHELL -- END -- $(date)"
echo
