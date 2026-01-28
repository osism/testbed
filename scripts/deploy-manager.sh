#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY MANAGER"
echo

cat /opt/manager-vars.sh
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# create symlink for semver script
sudo ln -sf /opt/configuration/contrib/semver2.sh /usr/local/bin/semver

# print docker version on manager after seed stage
docker version

# deploy manager ervice
sh -c '/opt/configuration/scripts/deploy/000-manager.sh'

# bootstrap nodes
osism apply operator -u $IMAGE_NODE_USER -l testbed-nodes
osism apply --environment custom facts
osism apply bootstrap
osism apply fail2ban

# On CentOS the Ceph deployment only works with podman.
if [[ -e /etc/redhat-release ]]; then
    osism apply podman
fi

# copy network configuration
osism apply network

# deploy wireguard
osism apply wireguard

# prepare wireguard configuration
sh -c '/opt/configuration/scripts/prepare-wireguard-configuration.sh'

# apply workarounds
osism apply --environment custom workarounds

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# The role can only be applied after the nodes have been rebooted as a necessary
# kernel module is only then available.
osism apply hddtemp

# restart the manager services to update the /etc/hosts file
if [[ $(semver $MANAGER_VERSION 7.1.1) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    sudo systemctl restart manager.service
else
    sudo systemctl restart docker-compose@manager
fi

# wait for manager service
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    wait_for_container_healthy 60 ceph-ansible
fi
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# disable ara service
if [[ "$IS_ZUUL" == "true" || "$ARA" == "false" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# gather facts
osism apply gather-facts

# create symlinks for deploy scripts
sudo ln -sf /opt/configuration/scripts/deploy/001-helpers.sh /usr/local/bin/deploy-helper
sudo ln -sf /opt/configuration/scripts/deploy/100-ceph-with-ansible.sh /usr/local/bin/deploy-ceph-with-ansible
sudo ln -sf /opt/configuration/scripts/deploy/100-ceph-with-rook.sh /usr/local/bin/deploy-ceph-with-rook
sudo ln -sf /opt/configuration/scripts/deploy/200-infrastructure.sh /usr/local/bin/deploy-infrastructure
sudo ln -sf /opt/configuration/scripts/deploy/300-openstack.sh /usr/local/bin/deploy-openstack
sudo ln -sf /opt/configuration/scripts/deploy/320-openstack-minimal.sh /usr/local/bin/deploy-openstack-minimal
sudo ln -sf /opt/configuration/scripts/deploy/400-monitoring.sh /usr/local/bin/deploy-monitoring
sudo ln -sf /opt/configuration/scripts/deploy/500-kubernetes.sh /usr/local/bin/deploy-kubernetes
sudo ln -sf /opt/configuration/scripts/deploy/510-clusterapi.sh /usr/local/bin/deploy-kubernetes-clusterapi

# create symlinks for upgrade scripts
sudo ln -sf /opt/configuration/scripts/upgrade-manager.sh /usr/local/bin/upgrade-manager
sudo ln -sf /opt/configuration/scripts/upgrade/100-ceph-with-ansible.sh /usr/local/bin/upgrade-ceph-with-ansible
sudo ln -sf /opt/configuration/scripts/upgrade/100-ceph-with-rook.sh /usr/local/bin/upgrade-ceph-with-rook
sudo ln -sf /opt/configuration/scripts/upgrade/200-infrastructure.sh /usr/local/bin/upgrade-infrastructure
sudo ln -sf /opt/configuration/scripts/upgrade/300-openstack.sh /usr/local/bin/upgrade-openstack
sudo ln -sf /opt/configuration/scripts/upgrade/320-openstack-minimal.sh /usr/local/bin/upgrade-openstack-minimal
sudo ln -sf /opt/configuration/scripts/upgrade/400-monitoring.sh /usr/local/bin/upgrade-monitoring
sudo ln -sf /opt/configuration/scripts/upgrade/500-kubernetes.sh /usr/local/bin/upgrade-kubernetes
sudo ln -sf /opt/configuration/scripts/upgrade/510-clusterapi.sh /usr/local/bin/upgrade-kubernetes-clusterapi

# create symlinks for bootstrap scripts
sudo ln -sf /opt/configuration/scripts/bootstrap/300-openstack.sh /usr/local/bin/bootstrap-openstack
sudo ln -sf /opt/configuration/scripts/bootstrap/301-openstack-octavia-amhpora-image.sh /usr/local/bin/bootstrap-octavia
sudo ln -sf /opt/configuration/scripts/bootstrap/302-openstack-k8s-clusterapi-images.sh /usr/local/bin/bootstrap-clusterapi

# create symlinks for other scripts
sudo ln -sf /opt/configuration/scripts/disable-local-registry.sh /usr/local/bin/disable-local-registry
sudo ln -sf /opt/configuration/scripts/pull-images.sh /usr/local/bin/pull-images

if [[ "$EXTERNAL_API" == "true" ]]; then
    sh -c '/opt/configuration/scripts/customisations/external-api.sh'
fi
