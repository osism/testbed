#!/usr/bin/env bash
set -x
set -e

server_ping() {
    for address in $(openstack --os-cloud test floating ip list --status ACTIVE -f value -c "Floating IP Address" | tr -d '\r'); do
        ping -c3 $address
    done
}

server_list() {
    openstack --os-cloud test server list
    openstack --os-cloud test server show test
    openstack --os-cloud test server show test-1
    openstack --os-cloud test server show test-2
    openstack --os-cloud test server show test-3
    openstack --os-cloud test server show test-4
}

# Listing the services and the hypervisors proves nothing on its own: both
# commands exit 0 whatever they print. Two failures seen in practice are
# invisible that way -- a compute_id that disagrees with the database leaves
# every nova-compute down (osism/issues#1447), and a broken Ceph client leaves
# the services up while the resource tracker never registers a hypervisor, so
# the cloud cannot place an instance on any of them.
nova_compute_consistent() {
    local services down n_services n_hypervisors
    services=$(openstack compute service list --service nova-compute -f value -c Host -c State)

    if [[ -z "${services//[[:space:]]/}" ]]; then
        echo "FAIL: no nova-compute service is registered"
        return 1
    fi

    down=$(awk '$2 != "up" { printf "%s ", $1 }' <<<"$services")
    if [[ -n "$down" ]]; then
        echo "FAIL: nova-compute is not up on: ${down}"
        return 1
    fi

    # Counting rather than matching names: a hypervisor's name is the one
    # libvirt reports, which need not equal the service host.
    n_services=$(awk 'NF { c++ } END { print c+0 }' <<<"$services")
    n_hypervisors=$(openstack hypervisor list -f value -c ID | awk 'NF { c++ } END { print c+0 }')
    if [[ "$n_services" -ne "$n_hypervisors" ]]; then
        echo "FAIL: ${n_services} nova-compute services but ${n_hypervisors} hypervisors"
        return 1
    fi

    echo "OK: ${n_services} nova-compute services up, ${n_hypervisors} hypervisors"
}

compute_list() {
    osism manage compute list testbed-node-3
    osism manage compute list testbed-node-4
    osism manage compute list testbed-node-5
}

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

nova_compute_consistent

echo
echo "# Run OpenStack test play"
echo

osism apply --environment openstack test
server_list
server_ping

if [[ $MANAGER_VERSION == "latest" ]]; then
    compute_list

    # testbed-node-3 -> testbed-node-4
    osism manage compute migrate --yes --target testbed-node-3 testbed-node-4
    compute_list
    server_ping

    # testbed-node-3 -> testbed-node-5
    osism manage compute migrate --yes --target testbed-node-3 testbed-node-5
    compute_list
    server_ping

    # testbed-node-4 -> testbed-node-3
    osism manage compute migrate --yes --target testbed-node-4 testbed-node-3
    compute_list
    server_ping

    # testbed-node-5 -> testbed-node-4
    osism manage compute migrate --yes --target testbed-node-5 testbed-node-4
    compute_list
    server_ping
fi
