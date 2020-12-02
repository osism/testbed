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

apt-get install --yes \
  ifupdown \
  python3-pip \
  python3-argcomplete \
  python3-crypto \
  python3-dnspython \
  python3-jmespath \
  python3-kerberos \
  python3-libcloud \
  python3-lockfile \
  python3-netaddr \
  python3-ntlm-auth \
  python3-requests-kerberos \
  python3-requests-ntlm \
  python3-selinux \
  python3-winrm \
  python3-xmltodict

pip3 install --no-cache-dir 'ansible>=2.10'

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

mkdir -p /usr/share/ansible

ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

ansible-playbook -i localhost, /opt/node.yml
