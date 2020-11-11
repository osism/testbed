#!/usr/bin/env bash

echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

apt-get install --yes python3-netifaces
python3 /root/configure-network-devices.py

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

add-apt-repository --yes ppa:ansible/ansible
apt-get install --yes ansible

ansible-galaxy install git+https://github.com/osism/ansible-docker

git clone https://github.com/osism/ansible-collection-commons.git /tmp/ansible-collection-commons
( cd /tmp/ansible-collection-commons; ansible-galaxy collection build; ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-commons-*.tar.gz; )
rm -rf /tmp/ansible-collection-commons

git clone https://github.com/osism/ansible-collection-services.git /tmp/ansible-collection-services
( cd /tmp/ansible-collection-services; ansible-galaxy collection build; ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-services-*.tar.gz; )
rm -rf /tmp/ansible-collection-services

ansible-playbook -i localhost, /opt/node.yml
