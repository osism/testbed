#!/usr/bin/env bash
set -x
set -e

source /opt/manager-vars.sh
export INTERACTIVE=false

osism apply k3s

# NOTE: The following lines will be moved to a osism.services.clusterapi role

CAPI_VERSION="v1.5.1"
CAPO_VERSION="v0.8.0"

export KUBECONFIG=$HOME/.kube/config

# add openstack-control-plane label to all hosts labeled control-plane
OS_CONTROL_PLANE_NODES=$(kubectl get nodes | grep control-plane | awk '{print $1}')
for NODE in $OS_CONTROL_PLANE_NODES; do
    kubectl label node "${NODE}" openstack-control-plane=enabled
done

# add worker node-role label to all hosts without a role
NODES_WITHOUT_ROLE=$(kubectl get nodes | grep '<none>' | awk '{print $1}')
for NODE in $NODES_WITHOUT_ROLE; do
    kubectl label node "${NODE}" node-role.kubernetes.io/worker=worker
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

# NOTE: The following lines will be moved to a osism.commons.helm role

# install helm

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# NOTE: The following lines will be moved to a osism.services.kubernetes_dashboard role

# deploy kubernetes dashboard

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
