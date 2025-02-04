#!/usr/bin/env bash
set -e

source /opt/configuration/scripts/include.sh
source /opt/configuration/scripts/manager-version.sh

default_dns_servers="$(get_default_dns_servers)"
sed -i "s/designate_forwarders_addresses: .*/designate_forwarders_addresses: \"$default_dns_servers\"/" /opt/configuration/environments/kolla/configuration.yml
