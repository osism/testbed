=====
Usage
=====

.. contents::
   :local:

Wireguard
=========

* deployment

  .. code-block:: console

     osism-run custom wireguard

* client configuration

  .. code-block:: console

     [Interface]
     PrivateKey = eFvxE9jOhSRg4drIUBEO1xqHP9cpV0bQiGASFqvGMkU=
     Address = 192.168.60.4/24

     [Peer]
     PublicKey = MANAGER_CONTENTS_OF_/etc/wireguard/osism.pub
     PresharedKey = MANAGER_CONTENTS_OF_/etc/wireguard/osism.psk
     AllowedIPs = 192.168.60.5/32, 192.168.50.0/24, 192.168.90.0/24, 192.168.100.0/24
     Endpoint = MANAGER_PUBLIC_IP_ADDRESS:51820

Change versions
===============

* Go to ``/opt/configuration`` on the manager node
* Run ``./scripts/set-openstack-version.sh stein`` to set the OpenStack version to ``stein``
* Run ``./scripts/set-ceph-version.sh nautilus`` to set the Ceph version to ``nautilus``
* Go to ``/home/dragon`` on the manager node
* Run ``ansible-playbook manager-part-2.yml`` to update the manager

This can also be achieved automatically by passing the wanted versions inside the environment
``ceph_version`` and ``openstack_version`` respectively.

Deploy services
===============

* Infrastructure services

  .. code-block:: console

     /opt/configuration/scripts/deploy_infrastructure_services.sh

* Ceph services

  .. code-block:: console

     /opt/configuration/scripts/deploy_ceph_services.sh

* Basic OpenStack services

  .. code-block:: console

     /opt/configuration/scripts/deploy_openstack_services_basic.sh

* Additional OpenStack services

  .. code-block:: console

     /opt/configuration/scripts/deploy_openstack_services_additional.sh

Purge services
==============

These commands completely remove parts of the environment. This makes reuse possible
without having to create a completely new environment.

OpenStack & infrastructure services
-----------------------------------

.. code-block:: console

   osism-kolla _ purge
   Are you sure you want to purge the kolla environment? [no]: yes
   Are you really sure you want to purge the kolla environment? [no]: ireallyreallymeanit

Ceph
----

.. code-block:: console

   find /opt/configuration -name 'ceph*keyring' -exec rm {} \;
   osism-ceph purge-docker-cluster
   Are you sure you want to purge the cluster? Note that if with_pkg is not set docker
   packages and more will be uninstalled from non-atomic hosts. Do you want to continue?
    [no]: yes

Manager services
----------------

.. code-block:: console

   cd /opt/manager
   docker-compose down -v

Some services like phpMyAdmin or OpenStackClient will still run afterwards.

Webinterfaces
=============

================ ========================== ======== ========================================
Name             URL                        Username Password
================ ========================== ======== ========================================
ARA              http://192.168.40.5:8120   ara      S6JE2yJUwvraiX57
Cockpit          https://192.168.40.5:8130  dragon   da5pahthaew2Pai2
Horizon          http://192.168.50.200      admin    pYV8bV749aDMXLPlYJwoJs4ouRPWezCIOXYAQP6v
Kibana           http://192.168.50.200:5601 kibana   k2ReobFEsoxNm3DyZnkZmFPadSnCz6BjQhaLFoyB
Netdata          http://192.168.50.5:19999  -        -
phpMyAdmin       http://192.168.40.5:8110   root     qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i
Skydive          http://192.168.50.5:8085   -        -
================ ========================== ======== ========================================

Tools
=====

Refstack
--------

.. code-block:: console

   /opt/configuration/contrib/refstack/refstack.sh
   [...]
   ======
   Totals
   ======
   Ran: 285 tests in 1306.4010 sec.
    - Passed: 283
    - Skipped: 2
    - Expected Fail: 0
    - Unexpected Success: 0
    - Failed: 0
Sum of execute time for each test: 1027.4324 sec.

Check infrastructure services
-----------------------------

The contrib directory contains a script to check the clustered infrastructure services. The
configuration is so that two nodes are already sufficient.

.. code-block:: console

   cd /opt/configuration/contrib
   ./check_infrastructure_services.sh
   Elasticsearch   OK - elasticsearch (kolla_logging) is running. status: green; timed_out: false; number_of_nodes: 2; ...

   MariaDB         OK: number of NODES = 2 (wsrep_cluster_size)

   RabbitMQ        RABBITMQ_CLUSTER OK - nb_running_node OK (2) nb_running_disc_node OK (2) nb_running_ram_node OK (0)

   Redis           TCP OK - 0.002 second response time on 192.168.50.10 port 6379|time=0.001901s;;;0.000000;10.000000

Random data
-----------

The contrib directory contains some scripts to fill the components of the environment with random data.
This is intended to generate a realistic data load, e.g. for upgrades or scaling tests.

MySQL
~~~~~

After deployment of MariaDB including HAProxy it is possible to create four test databases each with
four tables which are filled with randomly generated data. The script can be executed multiple
times to generate more data.

.. code-block:: console

   cd /opt/configuration/contrib
   ./mysql_random_data_load.sh 100000

Elasticsearch
~~~~~~~~~~~~~

After deployment of Elasticsearch including HAProxy it is possible to create 14 test indices
which are filled with randomly generated data. The script can be executed multiple times to
generate more data.

14 indices are generated because the default retention time for the number of retained
indices is set to 14.

.. code-block:: console

   cd /opt/configuration/contrib
   ./elasticsearch_random_data_load.sh 100000

Recipes
=======

This section describes how individual parts of the testbed can be deployed.

* Ceph

  .. code-block:: console

     osism-ceph testbed
     osism-run custom fetch-ceph-keys
     osism-infrastructure helper --tags cephclient

* Clustered infrastructure services

  .. code-block:: console

     osism-kolla deploy common,haproxy,elasticsearch,rabbitmq,mariadb,redis

* Infrastructure services (also deploy `Clustered infrastructure services`)

  .. code-block:: console

     osism-kolla deploy openvswitch,memcached,etcd,kibana

* Basic OpenStack services (also deploy `Infrastructure services`, `Clustered infrastructure services`, and `Ceph`)

  .. code-block:: console

     osism-kolla deploy keystone,horizon,placement,glance,cinder,neutron,nova
     osism-infrastructure helper --tags openstackclient
     osism-custom run bootstrap-basic

* Additional OpenStack services (also deploy `Basic OpenStack services` and all requirements)

  .. code-block:: console

     osism-kolla deploy heat,gnocchi,ceilometer,aodh,panko,magnum,barbican,designate

* Network analyzer (also deploy `Clustered infrastructure services`, `Infrastructure services`, and `Basic OpenStack services`)

  .. code-block:: console

     osism-kolla deploy skydive

  The Skydive agent creates a high load on the Open vSwitch services. Therefore the agent is only
  started manually when needed.

  .. code-block:: console

     osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent

* Realtime monitoring

  .. code-block:: console

     osism-infrastructure netdata

  .. figure:: /images/netdata.png

* Cockpit

  .. code-block:: console

     osism-generic cockpit
     osism-run custom generate-ssh-known-hosts

  .. figure:: /images/cockpit.png
