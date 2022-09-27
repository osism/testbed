#!/usr/bin/env bash

if [[ $IFACE == "{{ ansible_local.testbed_network_devices.management }}" ]]; then
    ip link add vxlan0 type vxlan id 42 group 239.1.1.1 dstport 4789 dev {{ ansible_local.testbed_network_devices.management }}
    ip addr add {{ '192.168.112.0/20' | ansible.netcommon.ipaddr('net') | ansible.netcommon.ipaddr(node_id) | ansible.netcommon.ipaddr('address') }}/20 dev vxlan0
    ip link set up dev vxlan0
fi
