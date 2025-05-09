#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY BAREMETAL SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

sed -i 's/enable_ironic: "no"/enable_ironic: "yes"/' /opt/configuration/environments/kolla/configuration.yml
sed -i 's/glance_backend_ceph: "yes"/glance_backend_ceph: "no"/' /opt/configuration/environments/kolla/configuration.yml
sed -i 's/glance_backend_file: "no"/glance_backend_file: "yes"/' /opt/configuration/environments/kolla/configuration.yml

echo 'enable_cinder: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_horizon: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_neutron: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_nova: "no"' >> /opt/configuration/environments/kolla/configuration.yml

osism apply -e custom baremetal-prepare
osism sync inventory
osism apply network -e network_allow_service_restart=true

# pull images
sh -c '/opt/configuration/scripts/pull-images.sh'

osism apply common
osism apply loadbalancer
osism apply openstackclient
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq

osism apply keystone
osism apply glance

osism apply -e custom baremetal-bootstrap
osism sync facts
osism apply ironic

osism apply tenks -e ireallymeanit=yes -e tenks_override_file=/opt/configuration/environments/custom/files/baremetal-tenks-override.yml
osism apply -e custom baremetal-netbox
sh -c '/opt/configuration/scripts/bootstrap/000-netbox.sh'

osism apply homer
