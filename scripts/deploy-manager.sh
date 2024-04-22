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

# bootstrap nodes
osism apply operator -u ubuntu
osism apply --environment custom facts
osism apply bootstrap

# copy network configuration
osism apply network

# deploy wireguard
osism apply wireguard

# prepare wireguard configuration
if [[ -e /home/dragon/wg0-dragon.conf ]]; then
    # on OSISM < 5.0.0 this file is not yet present.
    mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
fi

sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(curl my.ip.fi)/ /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME - dragon private key/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf

# apply workarounds
osism apply --environment custom workarounds

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# restart the manager services to update the /etc/hosts file
sudo systemctl restart docker-compose@manager

# wait for manager service
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# create symlinks for deploy scripts
sudo ln -s /opt/configuration/scripts/deploy/001-helper-services.sh /usr/local/bin/deploy-helper
sudo ln -s /opt/configuration/scripts/deploy/005-kubernetes.sh /usr/local/bin/deploy-kubernetes
sudo ln -s /opt/configuration/scripts/deploy/100-ceph-services-basic.sh /usr/local/bin/deploy-ceph
sudo ln -s /opt/configuration/scripts/deploy/200-infrastructure-services-basic.sh /usr/local/bin/deploy-infrastructure
sudo ln -s /opt/configuration/scripts/deploy/300-openstack-services-basic.sh /usr/local/bin/deploy-openstack
sudo ln -s /opt/configuration/scripts/deploy/400-monitoring-services.sh /usr/local/bin/deploy-monitoring

# create symlinks for upgrade scripts
sudo ln -s /opt/configuration/scripts/upgrade/100-ceph-services.sh /usr/local/bin/upgrade-ceph
sudo ln -s /opt/configuration/scripts/upgrade/200-infrastructure-services-basic.sh /usr/local/bin/upgrade-infrastructure
sudo ln -s /opt/configuration/scripts/upgrade/300-openstack-services-basic.sh /usr/local/bin/upgrade-openstack
sudo ln -s /opt/configuration/scripts/upgrade/400-monitoring-services.sh /usr/local/bin/upgrade-monitoring

# create symlinks for bootstrap scripts
sudo ln -s /opt/configuration/scripts/bootstrap/300-openstack-services.sh /usr/local/bin/bootstrap-openstack

sudo ln -s /opt/configuration/scripts/bootstrap/301-openstack-octavia-amhpora-image.sh /usr/local/bin/bootstrap-octavia
sudo ln -s /opt/configuration/scripts/bootstrap/302-openstack-k8s-clusterapi-images.sh /usr/local/bin/bootstrap-clusterapi
