#!/usr/bin/env bash
set -x
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

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
openstack --os-cloud test server list

compute_list() {
    osism manage compute list testbed-node-3
    osism manage compute list testbed-node-4
    osism manage compute list testbed-node-5
}

if [[ $MANAGER_VERSION == "latest" ]]; then
    compute_list
    osism manage compute migrate --yes --target testbed-node-3 testbed-node-4
    osism manage compute migrate --yes --target testbed-node-3 testbed-node-5
    compute_list
    osism manage compute migrate --yes --target testbed-node-4 testbed-node-3
    compute_list
    osism manage compute migrate --yes --target testbed-node-5 testbed-node-4
fi
