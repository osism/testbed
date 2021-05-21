=====
Usage
=====

.. contents::
   :local:

Wireguard
=========

* deployment (Wireguard is rolled out by default)

  .. code-block:: console

     osism-run custom wireguard

* client configuration can be found in ``/home/dragon/wireguard-client.conf`` on
  ``testbed-manager``, ``MANAGER_PUBLIC_IP_ADDRESS`` has to be replaced by the
  public address of ``testbed-manager``

Change versions
===============

* Go to ``/opt/configuration`` on the manager node
* Run ``./scripts/set-openstack-version.sh xena`` to set the OpenStack version to ``xena``
* Run ``./scripts/set-ceph-version.sh pacific`` to set the Ceph version to ``pacific``
* Go to ``/home/dragon`` on the manager node
* Run ``ansible-playbook manager-part-2.yml`` to update the manager

This can also be achieved automatically by passing the wanted versions inside the environment
``ceph_version`` and ``openstack_version`` respectively.

Deploy services
===============

* Basic infrastructure services (MariaDB, RabbitMQ, Redis, ..)

  .. code-block:: console

     /opt/configuration/scripts/002-infrastructure-services-basic.sh

* Extented infrastructure services (Patchman, phpMyAdmin, Cockpit, ..)

  .. code-block:: console

     /opt/configuration/scripts/006-infrastructure-services-extented.sh

* Ceph services

  .. code-block:: console

     /opt/configuration/scripts/003-ceph-services.sh

* Basic OpenStack services (Compute, Storage, ..)

  .. code-block:: console

     /opt/configuration/scripts/004-openstack-services-basic.sh

* Extented OpenStack services (Telemetry, Kubernetes, ..)

  .. code-block:: console

     /opt/configuration/scripts/007-openstack-services-extented.sh

* Additional OpenStack services (Rating, Container, ..)

  .. code-block:: console

     /opt/configuration/scripts/008-openstack-services-additional.sh

* Monitoring services (Netdata, Prometheus exporters, ..)

  .. code-block:: console

     /opt/configuration/scripts/005-monitoring-services.sh

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
ARA              http://192.168.16.5:8120   ara      password
AWX              http://192.168.16.5:8052   dragon   vaeh7eingix8ooPi
Ceph             http://192.168.16.9:7000   admin    phoon7Chahvae6we
Cockpit          https://192.168.16.5:8130  dragon   da5pahthaew2Pai2
Horizon          http://192.168.16.9        admin    pYV8bV749aDMXLPlYJwoJs4ouRPWezCIOXYAQP6v
Keycloak         http://192.168.16.5:8170   admin    password
Kibana           http://192.168.16.9:5601   kibana   k2ReobFEsoxNm3DyZnkZmFPadSnCz6BjQhaLFoyB
Netbox           http://192.168.16.5:8121   netbox   password
Netdata          http://192.168.16.5:19999  -        -
Patchman         http://192.168.16.5:8150   patchman password
Skydive          http://192.168.16.5:8085   admin    pYV8bV749aDMXLPlYJwoJs4ouRPWezCIOXYAQP6v
phpMyAdmin       http://192.168.16.5:8110   root     qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i
Zabbix           http://192.168.16.5:8160   Admin    zabbix
================ ========================== ======== ========================================

ARA
---

.. figure:: /images/ara.png

AWX
---

.. figure:: /images/awx.png

Ceph
----

Deploy `Ceph` first.

.. code-block:: console

   osism-run custom bootstraph-ceph-dashboard

.. figure:: /images/ceph-dashboard.png

Cockpit
-------

.. code-block:: console

   osism-generic cockpit
   osism-run custom generate-ssh-known-hosts

.. figure:: /images/cockpit.png

Keycloak
--------

.. code-block:: console

   osism-infrastructure keycloak

.. figure:: /images/keycloak.png

Netbox
------

Netbox is part of the manager and does not need to be deployed individually.

.. figure:: /images/netbox.png

Netdata
-------

.. code-block:: console

   osism-monitoring netdata

.. figure:: /images/netdata.png

Skydive
-------

Deploy `Clustered infrastructure services`, `Infrastructure services`, and
`Basic OpenStack services` first.

.. code-block:: console

   osism-kolla deploy skydive

The Skydive agent creates a high load on the Open vSwitch services. Therefore
the agent is only started manually when needed.

.. code-block:: console

   osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent

.. figure:: /images/skydive.png

Patchman
--------

.. code-block:: console

   osism-generic patchman-client
   osism-infrastructure patchman

Every night the package list of the clients is transmitted via cron. Initially
we transfer these lists manually.

.. code-block:: console

   osism-ansible generic all -m command -a patchman-client

After the clients have transferred their package lists for the first time the
database can be built by Patchman.

This takes some time on the first run. Later, this update will be done once a day
during the night via cron.

.. code-block:: console

   patchman-update

The previous steps can also be done with a custom playbook.

.. code-block:: console

   osism-run custom bootstrap-patchman

.. figure:: /images/patchman.png

Prometheus exporters
--------------------

Deploy `Clustered infrastructure services`, `Infrastructure services`, and
`Basic OpenStack services` first.

.. code-block:: console

   osism-kolla deploy prometheus

Zabbix
------

.. code-block:: console

   osism-monitoring zabbix-agent
   osism-monitoring zabbix

.. figure:: /images/zabbix.png

Tools
=====

Rally
-----

.. code-block:: console

   /opt/configuration/contrib/rally/rally.sh
   [...]
   Full duration: 6.30863

   HINTS:
   * To plot HTML graphics with this data, run:
       rally task report 002a01cd-46e7-4976-940f-943586771629 --out output.html

   * To generate a JUnit report, run:
       rally task export 002a01cd-46e7-4976-940f-943586771629 --type junit-xml --to output.xml

   * To get raw JSON output of task results, run:
       rally task report 002a01cd-46e7-4976-940f-943586771629 --json --out output.json

   At least one workload did not pass SLA criteria.

Refstack
--------

.. code-block:: console

   /opt/configuration/contrib/refstack/refstack.sh
   [...]
   ======
   Totals
   ======
   Ran: 286 tests in 1197.9323 sec.
    - Passed: 284
    - Skipped: 2
    - Expected Fail: 0
    - Unexpected Success: 0
    - Failed: 0
   Sum of execute time for each test: 932.9678 sec.

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

   Redis           TCP OK - 0.002 second response time on 192.168.16.10 port 6379|time=0.001901s;;;0.000000;10.000000

Random data
-----------

The contrib directory contains some scripts to fill the components of the
environment with random data. This is intended to generate a realistic data
load, e.g. for upgrades or scaling tests.

MySQL
~~~~~

After deployment of MariaDB including HAProxy it is possible to create four
test databases each with four tables which are filled with randomly generated
data. The script can be executed multiple times to generate more data.

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
     osism-infrastructure cephclient

* Clustered infrastructure services

  .. code-block:: console

     osism-kolla deploy common,haproxy,elasticsearch,rabbitmq,mariadb,redis

* Infrastructure services (also deploy `Clustered infrastructure services`)

  .. code-block:: console

     osism-kolla deploy openvswitch,memcached,etcd,kibana

* Basic OpenStack services (also deploy `Infrastructure services`,
  `Clustered infrastructure services`, and `Ceph`)

  .. code-block:: console

     osism-kolla deploy keystone,horizon,placement,glance,cinder,neutron,nova
     osism-infrastructure openstackclient
     osism-custom run bootstrap-basic

* Additional OpenStack services (also deploy `Basic OpenStack services` and all requirements)

  .. code-block:: console

     osism-kolla deploy heat,gnocchi,ceilometer,aodh,panko,magnum,barbican,designate
