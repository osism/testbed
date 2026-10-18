#!/usr/bin/env bash
set -e

# On OSISM < 5.0.0 this file is not yet present.
if [[ -e /home/dragon/wg0-dragon.conf ]]; then
    mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
fi

# The public address only ends up in the client configuration that
# users fetch for a VPN connection; nothing in the deployment reads it.
# A failed lookup therefore leaves the placeholder in place instead of
# failing the deployment.
public_ip_address=$(curl -fsS --retry 3 --max-time 10 my.ip.fi || true)
if [[ $public_ip_address =~ ^[0-9a-fA-F.:]+$ ]]; then
    sed -i -e "s/WIREGUARD_PUBLIC_IP_ADDRESS/$public_ip_address/" /home/dragon/wireguard-client.conf
else
    echo "WARNING: public IP address lookup failed, WIREGUARD_PUBLIC_IP_ADDRESS in /home/dragon/wireguard-client.conf must be set manually" >&2
fi
sed -i -e "s/CHANGEME.*/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf
