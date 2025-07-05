#!/usr/bin/env bash

if [[ $IFACE == "{{ internal_interface }}" ]]; then
    iptables -A FORWARD -i {{ internal_interface }} -j ACCEPT
    iptables -A FORWARD -o {{ internal_interface }} -j ACCEPT
    iptables -t nat -A POSTROUTING -o {{ internal_interface }} -j MASQUERADE

    iptables -t nat -A POSTROUTING -s 192.168.48.0/24 -d 172.31.252.0/23 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 192.168.48.0/24 -d 172.31.252.0/23 -j SNAT --to-source 192.168.48.1
fi
