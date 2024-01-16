#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh

export OS_CLOUD=admin

echo
echo "# OpenStack endpoints"
echo

openstack endpoint list

echo
echo "# Cinder"
echo

openstack volume service list

echo
echo "# Neutron"
echo

openstack network agent list
openstack network service provider list

echo
echo "# Nova"
echo

openstack compute service list
openstack hypervisor list

echo
echo "# Run OpenStack test play"
echo

osism apply --environment openstack test
