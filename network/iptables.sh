#!/usr/bin/env bash

if [[ $IFACE == "{{ internal_interface }}" ]]; then
    iptables -A FORWARD -i {{ internal_interface }} -j ACCEPT
    iptables -A FORWARD -o {{ internal_interface }} -j ACCEPT
    iptables -t nat -A POSTROUTING -o {{ internal_interface }} -j MASQUERADE
fi
