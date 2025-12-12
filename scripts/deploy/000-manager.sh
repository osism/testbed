#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
source /opt/configuration/scripts/include.sh

# The latest version of the Manager is used by default. If a different
# version is to be used, it must be used accordingly.

if [[ $MANAGER_VERSION != "latest" ]]; then
    /opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION
fi

# For a stable release, the versions of Ceph and OpenStack to use
# are set by the version of the stable release (set via the
# manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
fi

# disable ceph-ansible if rook should be used for the ceph deployment
if [[ $CEPH_STACK == "rook" ]]; then
    echo "enable_ceph_ansible: false" >> /opt/configuration/environments/manager/configuration.yml
fi

# enable new kubernetes service
if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    echo "enable_osism_kubernetes: true" >> /opt/configuration/environments/manager/configuration.yml
fi

if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 || $(semver $OPENSTACK_VERSION 2025.1 ) -ge 0 ]]; then
    sed -i "/^om_enable_rabbitmq_high_availability:/d" /opt/configuration/environments/kolla/configuration.yml
    sed -i "/^om_enable_rabbitmq_quorum_queues:/d" /opt/configuration/environments/kolla/configuration.yml
fi

# enable resource nodes
/opt/configuration/scripts/enable-resource-nodes.sh

if [[ -e /opt/venv/bin/activate ]]; then
    source /opt/venv/bin/activate
fi

ansible-playbook \
  -i testbed-manager, \
  --vault-password-file /opt/configuration/environments/.vault_pass \
  /opt/configuration/ansible/manager-part-3.yml

if [[ -e /opt/venv/bin/activate ]]; then
    deactivate
fi

cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# wait for manager service
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    wait_for_container_healthy 60 ceph-ansible
fi
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# disable ara service
if [[ "$IS_ZUUL" == "true" || "$ARA" == "false" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

docker compose --project-directory /opt/manager ps

# use osism.commons.still_alive stdout callback
if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    # The plugin is available in OSISM >= 7.0.0 and higher. In future, the callback
    # plugin will be used by default.
    sed -i "s/community.general.yaml/osism.commons.still_alive/" /opt/configuration/environments/ansible.cfg
fi

osism apply resolvconf -l testbed-manager
osism apply sshconfig
osism apply known-hosts
osism apply squid

if [[ $MANAGER_VERSION != "latest" ]]; then
  if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 ]]; then
    /opt/configuration/scripts/set-kolla-namespace.sh "kolla/release/$OPENSTACK_VERSION"
  else
    /opt/configuration/scripts/set-kolla-namespace.sh kolla/release
  fi
else
  /opt/configuration/scripts/set-kolla-namespace.sh kolla
fi

# use vxlan.sh networkd-dispatcher script for OSISM <= 9.0.0
if [[ $(semver $MANAGER_VERSION 9.0.0) -lt 0 && $MANAGER_VERSION != "latest" ]]; then
    sed -i 's|^# \(network_dispatcher_scripts:\)$|\1|g' \
      /opt/configuration/inventory/group_vars/testbed-nodes.yml
    sed -i 's|^# \(  - src: /opt/configuration/network/vxlan.sh\)$|\1|g' \
      /opt/configuration/inventory/group_vars/testbed-nodes.yml \
      /opt/configuration/inventory/group_vars/testbed-managers.yml
    sed -i 's|^# \(    dest: routable.d/vxlan.sh\)$|\1|g' \
      /opt/configuration/inventory/group_vars/testbed-nodes.yml \
      /opt/configuration/inventory/group_vars/testbed-managers.yml
fi
