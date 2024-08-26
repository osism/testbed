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

# deploy manager service
sh -c '/opt/configuration/scripts/deploy/000-manager-service.sh'

# Do not use the Keystone/Keycloak integration by default. We only use this integration
# in a special identity testbed.
rm -f /opt/configuration/environments/kolla/group_vars/keystone.yml
rm -f /opt/configuration/environments/kolla/files/overlays/keystone/wsgi-keystone.conf
rm -rf /opt/configuration/environments/kolla/files/overlays/keystone/federation

# bootstrap nodes
osism apply operator -u $IMAGE_NODE_USER -l testbed-nodes
osism apply --environment custom facts
osism apply bootstrap

# On CentOS the Ceph deployment only works with podman.
if [[ -e /etc/redhat-release ]]; then
    osism apply podman

    # There is currently some kind of race condition that prevents the custom network
    # facts from being executed because the netifaces module is not found although it
    # is actually installed. Therefore the facts are updated here again.
    osism apply --environment custom facts
    osism apply gather-facts
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
sudo systemctl restart docker-compose@manager

# wait for manager service
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    wait_for_container_healthy 60 ceph-ansible
fi
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# create symlinks for deploy scripts
sudo ln -sf /opt/configuration/scripts/deploy/001-helper-services.sh /usr/local/bin/deploy-helper
sudo ln -sf /opt/configuration/scripts/deploy/005-kubernetes.sh /usr/local/bin/deploy-kubernetes
sudo ln -sf /opt/configuration/scripts/deploy/006-kubernetes-clusterapi.sh /usr/local/bin/deploy-kubernetes-clusterapi
sudo ln -sf /opt/configuration/scripts/deploy/100-ceph-services.sh /usr/local/bin/deploy-ceph
sudo ln -sf /opt/configuration/scripts/deploy/100-rook-services.sh /usr/local/bin/deploy-rook
sudo ln -sf /opt/configuration/scripts/deploy/200-infrastructure-services.sh /usr/local/bin/deploy-infrastructure
sudo ln -sf /opt/configuration/scripts/deploy/300-openstack-services.sh /usr/local/bin/deploy-openstack
sudo ln -sf /opt/configuration/scripts/deploy/400-monitoring-services.sh /usr/local/bin/deploy-monitoring

# create symlinks for upgrade scripts
sudo ln -sf /opt/configuration/scripts/upgrade/005-kubernetes.sh /usr/local/bin/upgrade-kubernetes
sudo ln -sf /opt/configuration/scripts/upgrade/006-kubernetes-clusterapi.sh /usr/local/bin/upgrade-kubernetes-clusterapi
sudo ln -sf /opt/configuration/scripts/upgrade/100-ceph-services.sh /usr/local/bin/upgrade-ceph
sudo ln -sf /opt/configuration/scripts/upgrade/200-infrastructure-services.sh /usr/local/bin/upgrade-infrastructure
sudo ln -sf /opt/configuration/scripts/upgrade/300-openstack-services.sh /usr/local/bin/upgrade-openstack
sudo ln -sf /opt/configuration/scripts/upgrade/400-monitoring-services.sh /usr/local/bin/upgrade-monitoring

# create symlinks for bootstrap scripts
sudo ln -sf /opt/configuration/scripts/bootstrap/300-openstack-services.sh /usr/local/bin/bootstrap-openstack
sudo ln -sf /opt/configuration/scripts/bootstrap/301-openstack-octavia-amhpora-image.sh /usr/local/bin/bootstrap-octavia
sudo ln -sf /opt/configuration/scripts/bootstrap/302-openstack-k8s-clusterapi-images.sh /usr/local/bin/bootstrap-clusterapi

# create symlinks for other scripts
sudo ln -sf /opt/configuration/scripts/pull-images.sh /usr/local/bin/pull-images
sudo ln -sf /opt/configuration/scripts/disable-local-registry.sh /usr/local/bin/disable-local-registry

if [[ "$EXTERNAL_API" == "true" ]]; then
    sh -c '/opt/configuration/scripts/customisations/external-api.sh'
fi
