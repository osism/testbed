#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

osism apply kubernetes
osism apply clusterapi

# NOTE: The following lines will be moved to a osism.commons.helm role
# install helm

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# NOTE: The following lines will be moved to a kubernetes_dashboard play
# deploy kubernetes dashboard

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
