#!/usr/bin/env bash

apt-get install --yes python3-netifaces
python3 /root/configure-network-devices.py

cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
chown -R dragon:dragon /home/dragon/.ssh

sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-1.yml -e configuration_git_version=$CONFIGURATION_VERSION

sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-manager-version.sh $MANAGER_VERSION'

if [[ "$MANAGER_VERSION" == "latest" ]]; then
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh $CEPH_VERSION'
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh $OPENSTACK_VERSION'
else
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh $MANAGER_VERSION'
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh $MANAGER_VERSION'
fi

sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/enable-secondary-nodes.sh $NUMBER_OF_NODES'

sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-2.yml
sudo -iu dragon ansible-playbook -i testbed-manager.osism.test, /opt/manager-part-3.yml

sudo -iu dragon cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
    sleep 1;
done;

/root/cleanup.sh

# NOTE(berendt): sudo -E does not work here because sudo -i is needed

sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom cronjobs'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom facts'

sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic bootstrap'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic operator'

# copy network configuration
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic network'

# apply workarounds
sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom workarounds'

# reboot nodes
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic reboot -l testbed-nodes -e ireallymeanit=yes'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic wait-for-connection -l testbed-nodes -e ireallymeanit=yes'

# NOTE: Restart the manager services to update the /etc/hosts file
sudo -iu dragon sh -c 'docker-compose -f /opt/manager/docker-compose.yml restart'

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]];
do
    sleep 1;
done;

# deploy helper services
sudo -iu dragon sh -c '/opt/configuration/scripts/001-helper-services.sh'

# deploy identity services
# NOTE: All necessary infrastructure services are also deployed.
if [[ "$DEPLOY_IDENTITY" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/999-identity-services.sh'
fi

# deploy infrastructure services
if [[ "$DEPLOY_INFRASTRUCTURE" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/002-infrastructure-services-basic.sh'
    sudo -iu dragon sh -c '/opt/configuration/scripts/006-infrastructure-services-extented.sh'
fi

# deploy ceph services
if [[ "$DEPLOY_CEPH" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/003-ceph-services.sh'
fi

# deploy openstack services
if [[ "$DEPLOY_OPENSTACK" == "true" ]]; then
    if [[ "$DEPLOY_INFRASTRUCTURE" != "true" ]]; then
        echo "infrastructure services are necessary for the deployment of OpenStack"
    else
        sudo -iu dragon sh -c '/opt/configuration/scripts/004-openstack-services-basic.sh'
        sudo -iu dragon sh -c '/opt/configuration/scripts/009-openstack-services-baremetal.sh'
    fi
fi

# deploy monitoring services
if [[ "$DEPLOY_MONITORING" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/005-monitoring-services.sh'
fi
