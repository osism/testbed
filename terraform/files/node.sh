#!/usr/bin/env bash

source /etc/os-release

if [[ $UBUNTU_CODENAME == "focal" ]]; then
    # FIXME: Find better/prettier solution for it.

    # NOTE: Cloud Init may set a wrong default route. This is repaired manually here.

    ip route del default via 192.168.16.1 || true
    ip route del default via 192.168.32.1 || true
    ip route del default via 192.168.48.1 || true
    ip route del default via 192.168.64.1 || true
    ip route del default via 192.168.80.1 || true
    ip route del default via 192.168.96.1 || true
    ip route del default via 192.168.112.1 || true

    ip route add default via 192.168.16.1 || true
fi

# NOTE: Because DNS queries don't always work directly at the beginning a
#       retry for APT.
echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

if [[ $UBUNTU_CODENAME == "bionic" ]]; then

    # NOTE: Script is only needed for Bionic, the cloud-init on Focal initializes
    #       all NICs.
    apt-get install --yes python3-netifaces
    python3 /root/configure-network-devices.py
else
    apt-get update
fi

apt-get install --yes ifupdown python-netaddr python3-pip
pip3 install --no-cache-dir 'ansible>=2.10'

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

ansible-galaxy install git+https://github.com/osism/ansible-docker
ansible-galaxy collection install ansible.netcommon
ansible-galaxy collection install -v git+https://github.com/osism/ansible-collection-commons.git
ansible-galaxy collection install -v git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible/collections/ansible_collections

ansible-playbook -i localhost, /opt/node.yml
