#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY MANAGER"
echo

cat /opt/manager-vars.sh
echo

source /opt/manager-vars.sh
export INTERACTIVE=false

# deploy manager service
sh -c '/opt/configuration/scripts/deploy/000-manager-service.sh'

if [[ $IS_ZUUL == "true" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

# bootstrap nodes
osism apply operator -u ubuntu
osism apply --environment custom facts
osism apply bootstrap
osism apply hosts

# copy network configuration
osism apply network

# deploy wireguard
osism apply wireguard

# On OSISM < 5.0.0 this file is not yet present.
if [[ -e /home/dragon/wg0-dragon.conf ]]; then
    mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
fi

sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(curl my.ip.fi)/ /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME - dragon private key/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf

# apply workarounds
osism apply --environment custom workarounds

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# Restart the manager services to update the /etc/hosts file
sudo systemctl restart docker-compose@manager

# NOTE: It is not possible to use nested virtualization @ OTC
if [[ -e /etc/OTC_region ]]; then
    echo "nova_compute_virt_type: qemu" >> /opt/configuration/environments/kolla/configuration.yml
fi
