#!/usr/bin/env bash
set -e

# On OSISM < 5.0.0 this file is not yet present.
if [[ -e /home/dragon/wg0-dragon.conf ]]; then
    mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
fi

sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(curl my.ip.fi)/ /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME.*/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf
