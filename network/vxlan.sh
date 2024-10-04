#!/usr/bin/env bash

if [[ $IFACE == "{{ internal_interface }}" ]]; then

{% if "network" in group_names or "manager" in group_names %}
    ip link add vxlan0 type vxlan id 42 group 239.1.1.1 dstport 4789 dev {{ internal_interface }}
    ip addr add {{ '192.168.112.0/20' | ansible.utils.ipaddr('net') | ansible.utils.ipaddr(node_id) | ansible.utils.ipaddr('address') }}/20 dev vxlan0
    ip link set up dev vxlan0
{% endif %}

    ip link add vxlan1 type vxlan id 23 group 239.1.1.1 dstport 4789 dev {{ internal_interface }}
    ip addr add {{ '192.168.128.0/20' | ansible.utils.ipaddr('net') | ansible.utils.ipaddr(node_id) | ansible.utils.ipaddr('address') }}/20 dev vxlan1
    ip link set up dev vxlan1
fi
