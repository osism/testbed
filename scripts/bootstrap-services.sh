#!/usr/bin/env bash
set -x
set -e

sh -c '/opt/configuration/scripts/bootstrap/300-openstack-services.sh'
sh -c '/opt/configuration/scripts/bootstrap/301-openstack-octavia-amhpora-image.sh'
