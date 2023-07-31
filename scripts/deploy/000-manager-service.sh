#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
export INTERACTIVE=false

/opt/configuration/scripts/set-manager-version.sh $MANAGER_VERSION

# For a stable release, the versions of Ceph and OpenStack to use
# are set by the version of the stable release (set via the
# manager_version parameter) and not by release names.

if [[ $MANAGER_VERSION == "latest" ]]; then
    /opt/configuration/scripts/set-ceph-version.sh $CEPH_VERSION
    /opt/configuration/scripts/set-openstack-version.sh $OPENSTACK_VERSION
fi

wait_for_container_healthy() {
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1

    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name)" == "healthy" ]]; do
        if (( attempt_num++ == max_attempts )); then
            return 1
        else
            sleep 5
        fi
    done
}

ansible-playbook \
  -i testbed-manager.testbed.osism.xyz, \
  --vault-password-file /opt/configuration/environments/.vault_pass \
  /opt/configuration/ansible/manager-part-3.yml

cp /home/dragon/.ssh/id_rsa.pub /opt/ansible/secrets/id_rsa.operator.pub

# wait for netbox service
if ! wait_for_container_healthy 60 netbox-netbox-1; then
    # The Netbox integration is not mandatory for the use of the testbed.
    # Therefore it is ok to skip if the deployment did not work. A separate
    # job will be created later for the integration tests of the netbox which
    # will then be built into osism/python-osism.
    echo The deployment of the Netbox did not work. Skip the Netbox integration.
else
    osism netbox import
    osism netbox init
    osism netbox manage 1000
    osism netbox connect 1000 --state a

    osism netbox disable --no-wait testbed-switch-0
    osism netbox disable --no-wait testbed-switch-1
    osism netbox disable --no-wait testbed-switch-2
fi

docker compose --project-directory /opt/manager ps
docker compose --project-directory /opt/netbox ps

osism apply sshconfig
osism apply known-hosts

osism apply squid

if [[ $MANAGER_VERSION == "latest" ]]; then
    osism apply k3s

    # NOTE: The following lines will be moved to an osism.services.clusterapi role
    export KUBECONFIG=$HOME/.kube/config
    kubectl label node testbed-manager openstack-control-plane=enabled
    # kubectl label node testbed-node-0 openstack-control-plane=enabled
    # kubectl label node testbed-node-1 openstack-control-plane=enabled
    # kubectl label node testbed-node-2 openstack-control-plane=enabled
    sudo curl -Lo /usr/local/bin/clusterctl https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.4.4/clusterctl-linux-amd64
    sudo chmod +x /usr/local/bin/clusterctl
    export EXP_CLUSTER_RESOURCE_SET=true
    export CLUSTER_TOPOLOGY=true
    clusterctl init \
      --core cluster-api:v1.4.4 \
      --bootstrap kubeadm:v1.4.4 \
      --control-plane kubeadm:v1.4.4 \
      --infrastructure openstack:v0.7.1
fi
