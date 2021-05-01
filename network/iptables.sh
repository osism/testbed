#!/usr/bin/env bash

if [[ $IFACE == "{{ ansible_local.testbed_network_devices.management }}" ]]; then
    iptables -A FORWARD -i {{ ansible_local.testbed_network_devices.management }} -j ACCEPT
    iptables -A FORWARD -o {{ ansible_local.testbed_network_devices.management }} -j ACCEPT
    iptables -t nat -A POSTROUTING -o {{ ansible_local.testbed_network_devices.management }} -j MASQUERADE
fi
