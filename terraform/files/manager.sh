#!/usr/bin/env bash

# NOTE: cloud-init may set a wrong default route. This is repaired manually here.
ip route del default via 192.168.16.1 || true
ip route del default via 192.168.112.1 || true
ip route add default via 192.168.16.1 || true

# NOTE: Because DNS queries don't always work directly at the beginning a
#       retry for APT.
echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

apt-get update
apt-get install --yes \
  python3-argcomplete \
  python3-crypto \
  python3-dnspython \
  python3-jmespath \
  python3-kerberos \
  python3-libcloud \
  python3-lockfile \
  python3-netaddr \
  python3-netifaces \
  python3-ntlm-auth \
  python3-pip \
  python3-requests-kerberos \
  python3-requests-ntlm \
  python3-selinux \
  python3-winrm \
  python3-xmltodict

# NOTE: There are cloud images on which Ansible is pre-installed.
apt-get remove --yes ansible

pip3 install --no-cache-dir 'ansible-core>=2.11.0,<2.12.0'
pip3 install --no-cache-dir 'ansible>=4.0.0,<5.0.0'

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

mkdir -p /usr/share/ansible

ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

ansible-playbook -i localhost, /opt/manager-part-0.yml

python3 /root/configure-network-devices.py

cp /home/ubuntu/.ssh/id_rsa /home/dragon/.ssh/id_rsa
cp /home/ubuntu/.ssh/id_rsa.pub /home/dragon/.ssh/id_rsa.pub
chown -R dragon:dragon /home/dragon/.ssh

sudo -iu dragon ansible-playbook -i testbed-manager.testbed.osism.xyz, /opt/manager-part-1.yml -e configuration_git_version=$CONFIGURATION_VERSION

sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-manager-version.sh $MANAGER_VERSION'

if [[ "$MANAGER_VERSION" == "latest" ]]; then
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh $CEPH_VERSION'
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh $OPENSTACK_VERSION'
else
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-ceph-version.sh $MANAGER_VERSION'
    sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/set-openstack-version.sh $MANAGER_VERSION'
fi

sudo -iu dragon sh -c 'cd /opt/configuration; ./scripts/enable-secondary-nodes.sh $NUMBER_OF_NODES'

sudo -iu dragon ansible-playbook -i testbed-manager.testbed.osism.xyz, /opt/manager-part-2.yml
sudo -iu dragon ansible-playbook -i testbed-manager.testbed.osism.xyz, /opt/manager-part-3.yml

sudo -iu dragon cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# NOTE(berendt): wait for ARA
until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' manager_ara-server_1)" == "healthy" ]]; do
    sleep 1;
done;

# NOTE(berendt): sudo -E does not work here because sudo -i is needed

sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic operator -l "all:!manager" -u ubuntu'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-run custom facts'
sudo -iu dragon sh -c 'INTERACTIVE=false osism-generic bootstrap'

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
