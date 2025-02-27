#!/usr/bin/env bash
set -x
set -e

echo
echo "# DEPLOY BAREMETAL SERVICES"
echo

source /opt/configuration/scripts/include.sh
source /opt/manager-vars.sh

sed -i 's/enable_ironic: "no"/enable_ironic: "yes"/' /opt/configuration/environments/kolla/configuration.yml

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
osism apply openvswitch --limit testbed-control-nodes
osism apply ovn --limit testbed-control-nodes

# deploy ceph services
if [[ $CEPH_STACK == "ceph-ansible" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-ceph-with-ansible.sh'
elif [[ $CEPH_STACK == "rook" ]]; then
    sh -c '/opt/configuration/scripts/deploy/100-ceph-with-rook.sh'
fi

osism apply keystone
osism apply placement
osism apply neutron

osism apply -e custom baremetal-bootstrap
osism sync facts
osism apply ironic

osism apply glance
osism apply nova --limit testbed-control-nodes

osism apply tenks -e ireallymeanit=yes -e tenks_override_file=/opt/configuration/environments/custom/files/baremetal-tenks-override.yml

osism apply designate
osism apply kolla-ceph-rgw
osism apply horizon
osism apply cinder
osism apply barbican
osism apply octavia

osism apply homer
