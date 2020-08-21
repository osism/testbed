#!/usr/bin/env bash

cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
chown -R dragon:dragon /home/dragon/.ssh

sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-configuration
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
sudo -iu dragon ansible-galaxy install git+https://github.com/osism/ansible-manager

sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /opt/manager-part-1.yml -e configuration_git_version=${var.configuration_version}
sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh ${var.ceph_version}'
sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh ${var.openstack_version}'

sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /opt/manager-part-2.yml
sudo -iu dragon ansible-playbook -i testbed-manager.osism.local, /opt/manager-part-3.yml

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

# reboot nodes
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic reboot -l "all:!manager" -e ireallymeanit=yes'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic wait-for-connection -l "all:!manager" -e ireallymeanit=yes'

# NOTE: Restart the manager services to update the /etc/hosts file
sudo -iu dragon sh -c 'docker-compose -f /opt/manager/docker-compose.yml restart'

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]];
do
    sleep 1;
done;

# deploy helper services
sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_helper_services.sh'

# deploy infrastructure services
if [[ "${var.deploy_infrastructure}" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_infrastructure_services_basic.sh'
fi

# deploy ceph services
if [[ "${var.deploy_ceph}" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_ceph_services.sh'
fi

# deploy openstack services
if [[ "${var.deploy_openstack}" == "true" ]]; then
    if [[ "${var.deploy_infrastructure}" != "true" ]]; then
        echo "infrastructure services are necessary for the deployment of OpenStack"
    else
        sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_openstack_services_basic.sh'

        if [[ "${var.run_refstack}" == "true" ]]; then
            sudo -iu dragon sh -c 'INTERACTIVE=false osism-run openstack bootstrap-refstack'
            sudo -iu dragon sh -c '/opt/configuration/contrib/refstack/refstack.sh'
        fi
    fi
fi

# deploy monitoring services
if [[ "${var.deploy_monitoring}" == "true" ]]; then
    sudo -iu dragon sh -c '/opt/configuration/scripts/deploy_monitoring_services.sh'
fi
