#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
export INTERACTIVE=false

osism apply k3s

CAPI_VERSION="v1.5.1"
CAPO_VERSION="v0.8.0"

# NOTE: The following lines will be moved to an osism.services.clusterapi role
export KUBECONFIG=$HOME/.kube/config
# add openstack-control-plane label to all hosts labeled control-plane
OS_CONTROL_PLANE_NODES=$(kubectl get nodes | grep control-plane | awk '{print $1}')
for NODE in $OS_CONTROL_PLANE_NODES; do
    kubectl label node "${NODE}" openstack-control-plane=enabled
done

sudo curl -Lo /usr/local/bin/clusterctl https://github.com/kubernetes-sigs/cluster-api/releases/download/${CAPI_VERSION}/clusterctl-linux-amd64
sudo chmod +x /usr/local/bin/clusterctl
export EXP_CLUSTER_RESOURCE_SET=true
export CLUSTER_TOPOLOGY=true
clusterctl init \
  --core cluster-api:${CAPI_VERSION} \
  --bootstrap kubeadm:${CAPI_VERSION} \
   --control-plane kubeadm:${CAPI_VERSION} \
  --infrastructure openstack:${CAPO_VERSION}
