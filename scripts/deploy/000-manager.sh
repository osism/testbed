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

# enable new kubernetes service
if [[ $(semver $MANAGER_VERSION 7.0.0) -ge 0 || $MANAGER_VERSION == "latest" ]]; then
    echo "enable_osism_kubernetes: true" >> /opt/configuration/environments/manager/configuration.yml
fi

if [[ $MANAGER_VERSION == "latest" || $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 || $(semver $OPENSTACK_VERSION 2025.1 ) -ge 0 ]]; then
    sed -i "/^om_enable_rabbitmq_high_availability:/d" /opt/configuration/environments/kolla/configuration.yml
    sed -i "/^om_enable_rabbitmq_quorum_queues:/d" /opt/configuration/environments/kolla/configuration.yml
fi

# enable resource nodes
/opt/configuration/scripts/enable-resource-nodes.sh

# cephadm authenticates to the Ceph hosts with a dedicated key of its own,
# not with the fleet-wide operator key: cephadm stores the key it is given in
# the Ceph configuration store, from where anyone with Ceph admin access reads
# it back with "ceph config-key get mgr/cephadm/ssh_identity_key". There is no
# existing key to copy for this one, so it is generated here. The public half
# is authorized on the ceph group only, see inventory/group_vars/ceph.yml.
#
# This runs before the manager role, which writes the private keys listed in
# private_keys to /opt/ansible/secrets. ceph_ssh_private_key is looked up from
# the file created here (environments/secrets.yml).
mkdir -p /opt/configuration/environments/secrets
if [[ ! -e /opt/configuration/environments/secrets/id_rsa.ceph ]]; then
    ssh-keygen -t rsa -b 4096 -N "" -C "" -m PEM \
      -f /opt/configuration/environments/secrets/id_rsa.ceph
fi
chmod 600 /opt/configuration/environments/secrets/id_rsa.ceph

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

# The manager role only writes the private keys, the public half is staged
# here. inventory/group_vars/ceph.yml reads it from the osism-ansible container,
# where /opt/ansible/secrets is mounted as /ansible/secrets.
cp /opt/configuration/environments/secrets/id_rsa.ceph.pub /opt/ansible/secrets/id_rsa.ceph.pub

# Make the operator private key reachable inside the osism/seed container.
# run.sh runs the keypair play inside the seed container, which bind-mounts
# only /opt/configuration; the host-path lookups in secrets.yml do not resolve
# there. Place a copy in the config dir so the lookup finds it.
mkdir -p /opt/configuration/environments/secrets
cp /home/dragon/.ssh/id_rsa /opt/configuration/environments/secrets/id_rsa.operator
chmod 600 /opt/configuration/environments/secrets/id_rsa.operator

# wait for manager service
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# disable ara service
if [[ "$IS_ZUUL" == "true" || "$ARA" == "false" ]]; then
    sh -c '/opt/configuration/scripts/disable-ara.sh'
fi

docker compose --project-directory /opt/manager ps

osism apply resolvconf -l testbed-manager
osism apply sshconfig
osism apply known-hosts
osism apply squid

if [[ $MANAGER_VERSION != "latest" ]]; then
  if [[ $(semver $MANAGER_VERSION 10.0.0-0) -ge 0 ]]; then
    KOLLA_OS_VERSION=$(docker inspect --format '{{ index .Config.Labels "de.osism.release.openstack"}}' kolla-ansible)
    /opt/configuration/scripts/set-kolla-namespace.sh "kolla/release/$KOLLA_OS_VERSION"
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
