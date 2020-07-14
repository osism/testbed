#!/usr/bin/env bash

echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

apt-get install --yes python3-netifaces
python3 /root/configure-network-devices.py

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

add-apt-repository --yes ppa:ansible/ansible
apt-get install --yes ansible

ansible-galaxy install git+https://github.com/osism/ansible-chrony
ansible-galaxy install git+https://github.com/osism/ansible-common
ansible-galaxy install git+https://github.com/osism/ansible-docker
ansible-galaxy install git+https://github.com/osism/ansible-docker-compose
ansible-galaxy install git+https://github.com/osism/ansible-operator
ansible-galaxy install git+https://github.com/osism/ansible-repository
ansible-galaxy install git+https://github.com/osism/ansible-resolvconf

ansible-playbook -i localhost, /opt/node.yml
