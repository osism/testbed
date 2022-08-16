#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh

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

ansible-playbook -i testbed-manager.testbed.osism.xyz, /opt/configuration/ansible/manager-part-3.yml --vault-password-file /opt/configuration/environments/.vault_pass

cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# NOTE(berendt): wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1

# NOTE(berendt): wait for netbox service
wait_for_container_healthy 30 netbox-netbox-1


export INTERACTIVE=false
osism netbox import --vendors Arista
osism netbox import --vendors Other --no-library
osism netbox init
osism netbox manage 1000
osism netbox connect 1000 --state a

osism apply operator -l "all:!manager" -u ubuntu
osism apply --environment custom facts
osism apply bootstrap

# copy network configuration
osism apply network

# deploy wireguard
osism apply wireguard
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(curl my.ip.fi)/ /home/dragon/wireguard-client.conf

# apply workarounds
osism apply --environment custom workarounds

# apply sosreport
osism apply sosreport

# reboot nodes
osism apply reboot -l testbed-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-nodes -e ireallymeanit=yes

# TODO(frickler): Restart systemd service instead?
# NOTE: Restart the manager services to update the /etc/hosts file
docker compose -f /opt/manager/docker-compose.yml restart

# NOTE(berendt): wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1

osism netbox disable testbed-switch-0
osism netbox disable testbed-switch-1
osism netbox disable testbed-switch-2

# NOTE: It is not possible to use nested virtualization @ OTC
if [[ -e /etc/OTC_region ]]; then
    echo "nova_compute_virt_type: qemu" >> /opt/configuration/environments/kolla/configuration.yml
fi

# deploy helper services
sh -c '/opt/configuration/scripts/001-helper-services.sh'

# deploy identity services
# NOTE: All necessary infrastructure services are also deployed.
if [[ "$DEPLOY_IDENTITY" == "true" ]]; then
    sh -c '/opt/configuration/scripts/999-identity-services.sh'
fi

# deploy infrastructure services
if [[ "$DEPLOY_INFRASTRUCTURE" == "true" ]]; then
    sh -c '/opt/configuration/scripts/002-infrastructure-services-basic.sh'
fi

# deploy ceph services
if [[ "$DEPLOY_CEPH" == "true" ]]; then
    sh -c '/opt/configuration/scripts/003-ceph-services.sh'
fi

# deploy openstack services
if [[ "$DEPLOY_OPENSTACK" == "true" ]]; then
    if [[ "$DEPLOY_INFRASTRUCTURE" != "true" ]]; then
        echo "infrastructure services are necessary for the deployment of OpenStack"
    else
        sh -c '/opt/configuration/scripts/004-openstack-services-basic.sh'
        sh -c '/opt/configuration/scripts/009-openstack-services-baremetal.sh'
    fi
fi

# deploy monitoring services
if [[ "$DEPLOY_MONITORING" == "true" ]]; then
    sh -c '/opt/configuration/scripts/005-monitoring-services.sh'
fi
