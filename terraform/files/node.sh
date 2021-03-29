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

# NOTE: There are cloud images on which Ansible is pre-installed.
apt-get remove --yes ansible

pip3 install --no-cache-dir 'ansible>=3.0.0,<4.0.0'

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

mkdir -p /usr/share/ansible

ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

ansible-playbook -i localhost, /opt/node.yml
