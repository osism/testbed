#!/usr/bin/env bash
set -x
set -e

echo
echo "# Kubernetes nodes"
echo

kubectl get nodes

echo
echo "# Cilium status"
echo

cilium status

echo
echo "# Cilium BGP peers"
echo

cilium bgp peers

echo
echo "# Cilium BGP routes"
echo

cilium bgp routes

echo
echo "# FRR BGP summary"
echo

sudo vtysh -c "show ip bgp summary"
