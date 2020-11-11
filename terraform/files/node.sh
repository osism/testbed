#!/usr/bin/env bash

source /etc/os-release

if [[ $UBUNTU_CODENAME == "focal" ]]; then
    # FIXME: Find better/prettier solution for it.

    # NOTE: Cloud Init may set a wrong default route. This is repaired manually here.

    ip route del default via 192.168.16.1 || exit 0
    ip route del default via 192.168.32.1 || exit 0
    ip route del default via 192.168.48.1 || exit 0
    ip route del default via 192.168.64.1 || exit 0
    ip route del default via 192.168.80.1 || exit 0
    ip route del default via 192.168.96.1 || exit 0
    ip route del default via 192.168.112.1 || exit 0

    ip route add default via 192.168.16.1 || exit 0
fi

echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

apt-get install --yes python3-netifaces
python3 /root/configure-network-devices.py

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

add-apt-repository --yes ppa:ansible/ansible
apt-get install --yes ansible python-netaddr

ansible-galaxy install git+https://github.com/osism/ansible-docker
ansible-galaxy collection install ansible.netcommon

git clone https://github.com/osism/ansible-collection-commons.git /tmp/ansible-collection-commons
( cd /tmp/ansible-collection-commons; ansible-galaxy collection build; ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-commons-*.tar.gz; )
rm -rf /tmp/ansible-collection-commons

git clone https://github.com/osism/ansible-collection-services.git /tmp/ansible-collection-services
( cd /tmp/ansible-collection-services; ansible-galaxy collection build; ansible-galaxy collection install -v -f -p /usr/share/ansible/collections osism-services-*.tar.gz; )
rm -rf /tmp/ansible-collection-services

ansible-playbook -i localhost, /opt/node.yml
