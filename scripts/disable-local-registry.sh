#!/usr/bin/env bash

sed -i "/^ceph_docker_registry:/d" /opt/configuration/environments/configuration.yml
sed -i "/^docker_registry:/d" /opt/configuration/environments/configuration.yml
sed -i "/^docker_registry_ansible:/d" /opt/configuration/environments/configuration.yml
sed -i "/^docker_registry_kolla:/d" /opt/configuration/environments/configuration.yml
sed -i "/^docker_registry_netbox:/d" /opt/configuration/environments/configuration.yml
