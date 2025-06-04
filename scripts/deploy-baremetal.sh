#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY BAREMETAL SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

# Reconfigure for a standalone ironic on the manager node
sed -n '/\[testbed-control-nodes\]/,/^$/{/^testbed-manager$/q 1}' /opt/configuration/inventory/10-custom && sed -i '/\[testbed-control-nodes\]/a testbed-manager' /opt/configuration/inventory/10-custom
sed -i '/\[testbed-control-nodes\]/, /^$/{s/^\(testbed-node-[012]\)/#\1/g}' /opt/configuration/inventory/10-custom
sed -i '/\[testbed-resource-nodes\]/, /^$/{s/^#\(testbed-node-[012]\)/\1/g}' /opt/configuration/inventory/10-custom

 sed -i 's/enable_ironic: "no"/enable_ironic: "yes"/' /opt/configuration/environments/kolla/configuration.yml
 sed -i 's/glance_backend_ceph: "yes"/glance_backend_ceph: "no"/' /opt/configuration/environments/kolla/configuration.yml
 sed -i 's/glance_backend_file: "no"/glance_backend_file: "yes"/' /opt/configuration/environments/kolla/configuration.yml

echo 'enable_ironic_dnsmasq: "yes"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_cinder: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_horizon: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_nova: "no"' >> /opt/configuration/environments/kolla/configuration.yml
echo 'enable_neutron: "no"' >> /opt/configuration/environments/kolla/configuration.yml
sed -i 's/testbed_baremetal_scenario: "no"/testbed_baremetal_scenario: "yes"/' /opt/configuration/environments/configuration.yml

echo -en "[libvirt:children]\ntestbed-resource-nodes" > /opt/configuration/inventory/50-tenks.yml

# Enable and apply netbox
echo 'enable_netbox: "yes"' >> /opt/configuration/environments/configuration.yml
osism apply netbox

# Reconfigure the listener service
sed -i '/^manager_listener_broker_hosts:$/,/^[^(  -)]/{s/^\(  -.*\)/#\1/g}' /opt/configuration/environments/manager/configuration.yml
sed -i '/^manager_listener_broker_hosts:$/a \ \ - 192.168.16.5' /opt/configuration/environments/manager/configuration.yml
osism apply manager -- -e manager_service_allow_restart=false
sudo systemctl restart manager.service
wait_for_container_healthy 60 kolla-ansible
wait_for_container_healthy 60 osism-ansible

# Sync updated inventory
osism sync inventory

# Apply OOB network (doing the manager network reload manually to avoid hangs)
osism apply network
sudo systemctl reload systemd-networkd.service
osism apply reboot -l testbed-resource-nodes -e ireallymeanit=yes
osism apply wait-for-connection -l testbed-resource-nodes -e ireallymeanit=yes

# pull images
osism apply -r 2 -e custom baremetal-pull-images

osism apply common
osism apply loadbalancer
osism apply openstackclient
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq

osism apply keystone
osism apply glance

osism apply ironic-download-ipa-images
osism apply -e custom baremetal-bootstrap
osism apply ironic -e enable_ironic_agent_download_images=false

osism manage images --filter Cirros

osism apply tenks -e ireallymeanit=yes -e tenks_override_file=/opt/configuration/environments/custom/files/baremetal-tenks-override.yml
osism apply -e custom baremetal-netbox
sh -c '/opt/configuration/scripts/bootstrap/000-netbox.sh'
