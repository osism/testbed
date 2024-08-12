#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh

MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)

if [[ $(docker exec ceph-ansible sh -c "test -f /ansible/ceph-configure-lvm-volumes.yml && echo OK") != "OK" ]]; then
    mkdir -p /opt/configuration/environments/custom/tasks /opt/configuration/environments/custom/templates
    curl -o /opt/configuration/environments/custom/playbook-ceph-configure-lvm-volumes.yml https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/ceph-configure-lvm-volumes.yml
    curl -o /opt/configuration/environments/custom/playbook-ceph-create-lvm-devices.yml https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/ceph-create-lvm-devices.yml
    curl -o /opt/configuration/environments/custom/playbook-ceph-pools.yml https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/quincy/ceph-pools.yml
    curl -o /opt/configuration/environments/custom/tasks/_add-device-links.yml https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/tasks/_add-device-links.yml
    curl -o /opt/configuration/environments/custom/tasks/_add-device-partitions.yml https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/tasks/_add-device-partitions.yml
    curl -o /opt/configuration/environments/custom/templates/ceph-configure-lvm-volumes.yml.j2 https://raw.githubusercontent.com/osism/container-image-ceph-ansible/main/files/playbooks/templates/ceph-configure-lvm-volumes.yml.j2
fi

# Make sure that no partitions are present
osism apply --environment custom wipe-partitions
osism apply facts

if [[ $MANAGER_VERSION =~ ^7\.[0-9]\.[0-9]$ || $MANAGER_VERSION == "latest" ]]; then
    # In preparation for deployment with Rook, the pre-built LVM2 volumes are always used
    # from OSISM 7 onwards.
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

    # With OSISM 7 we have introduced a play to manage the Ceph pools independently
    # of the play for the Ceph OSDs. The openstack_config parameter is therefore removed
    # and the new ceph-pools play is then used.
    sed -i "/^openstack_config:/d" /opt/configuration/environments/ceph/configuration.yml
fi
