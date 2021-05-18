#!/usr/bin/env bash

echo
echo "# OpenStack endpoints"
echo

openstack --os-cloud admin endpoint list

echo
echo "# Heat"
echo

openstack --os-cloud admin orchestration service list

echo
echo "# Cinder"
echo

openstack --os-cloud admin volume service list

echo
echo "# Neutron"
echo

openstack --os-cloud admin network agent list
openstack --os-cloud admin network service provider list

echo
echo "# Nova"
echo

openstack --os-cloud admin compute service list
openstack --os-cloud admin hypervisor list
