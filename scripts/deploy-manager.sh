#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY MANAGER"
echo

source /opt/manager-vars.sh
export INTERACTIVE=false

wait_for_container_healthy() {
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1

    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name)" == "healthy" ]]; do
        if (( attempt_num++ == max_attempts )); then
            return 1
        else
            sleep 5
        fi
    done
}

# deploy manager service
sh -c '/opt/configuration/scripts/deploy/000-manager-service.sh'

osism apply operator -u ubuntu
osism apply --environment custom facts
osism apply bootstrap
osism apply hosts

# copy network configuration
osism apply network

# deploy wireguard
osism apply wireguard
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(curl my.ip.fi)/ /home/dragon/wireguard-client.conf

# apply workarounds
osism apply --environment custom workarounds

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# NOTE: Restart the manager services to update the /etc/hosts file
sudo systemctl restart docker-compose@manager

# NOTE(berendt): wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1

# NOTE: It is not possible to use nested virtualization @ OTC
if [[ -e /etc/OTC_region ]]; then
    echo "nova_compute_virt_type: qemu" >> /opt/configuration/environments/kolla/configuration.yml
fi
