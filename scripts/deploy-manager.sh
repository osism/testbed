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

if [[ -e /etc/osism-ci-image ]]; then
    osism apply --environment custom workarounds-zuul
fi

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# restart the manager services to update the /etc/hosts file
sudo systemctl restart docker-compose@manager

# wait for manager service
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible
