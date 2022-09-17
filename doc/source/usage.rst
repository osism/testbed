=====
Usage
=====

.. contents::
   :local:


Infrastructure management
=========================

.. note::

   The following commands are executed from the ``testbed/terraform`` repository directory.

Get the URL for the VNC console from an instance (by default from the manager):

.. code-block:: console

   make console ENVIRONMENT=betacloud
   make console ENVIRONMENT=betacloud CONSOLE=node-0

Get the console log from an instance (by default from the manager):

.. code-block:: console

   make log ENVIRONMENT=betacloud
   make log ENVIRONMENT=betacloud CONSOLE=node-0

Open a login shell on the manager via SSH:

.. code-block:: console

   make ssh ENVIRONMENT=betacloud
   make login ENVIRONMENT=betacloud  # this is just an alias for "make ssh"

Create a tunnel for the internal networks (``192.168.16.0/20``,  ``192.168.112.0/20``)
via sshuttle (https://github.com/sshuttle/sshuttle):

.. code-block:: console

   make sshuttle ENVIRONMENT=betacloud
   make tunnel ENVIRONMENT=betacloud   # this is just an alias for "make sshuttle"

Show endpoint URLs (ara, phpmyadmin):

.. code-block:: console

   make endpoints ENVIRONMENT=betacloud

Show manager address:

.. code-block:: console

   make address ENVIRONMENT=betacloud

Open an Openstack Client Console:

.. code-block:: console

   make openstack ENVIRONMENT=betacloud

Copy a file to the manager:

.. code-block:: console

   make scp PARAMS=/file/to/be/copied SOURCE=/path/to/destination ENVIRONMENT=betacloud
   make copy PARAMS=/file/to/be/copied SOURCE=/path/to/destination ENVIRONMENT=betacloud # this is just an alias for "make scp"

Terraform
---------

Delete providers:

.. code-block:: console

   make reset ENVIRONMENT=betacloud

Init terraform, select workspace and copy override and custom files:

.. code-block:: console

   make init ENVIRONMENT=betacloud

Init terraform and validate:

.. code-block:: console

   make validate ENVIRONMENT=betacloud

Init terraform and import a resource:

.. code-block:: console

   make attach ENVIRONMENT=betacloud

Init terraform and remove a resource:

.. code-block:: console

   make detach ENVIRONMENT=betacloud

Init terraform and push a state to a remote backend:

.. code-block:: console

   make state-push ENVIRONMENT=betacloud
   make push ENVIRONMENT=betacloud       # this is just an alias for "make state-push"

Init terraform and generate a graph in DOT format:

.. code-block:: console

   make graph ENVIRONMENT=betacloud

Init terraform and show the current state:

.. code-block:: console

   make show ENVIRONMENT=betacloud

Init terraform and show the configuration of a specific resource:

.. code-block:: console

   make list ENVIRONMENT=betacloud

Decommissioning:

.. code-block:: console

   make clean ENVIRONMENT=betacloud

.. raw:: html
   :file: html/asciinema-tf-clean.html


Checks
------

Most of the checks require a full installation of OpenStack and Ceph.
Only ``ping`` works without them.

Check the installation via ping:

.. code-block:: console

   make ping ENVIRONMENT=betacloud

Run check script for openstack and infrastructure components:

.. code-block:: console

   make check ENVIRONMENT=betacloud

Run rally script (benchmark openstack):

.. code-block:: console

   make rally ENVIRONMENT=betacloud

Run refstack script:

.. code-block:: console

   make refstack ENVIRONMENT=betacloud


Internals
---------

These are used for make internal functions and not supposed to be used by a user:

.. code-block:: console

   make .deploy.$(ENVIRONMENT)          # check if a deployment is present
   make .MANAGER_ADDRESS.$(ENVIRONMENT) # return manager address
   make .id_rsa.$(ENVIRONMENT)          # write private key


Wireguard
=========

* deployment

  .. code-block:: console

     osism apply wireguard

* client configuration can be found in ``/home/dragon/wireguard-client.conf`` on
  ``testbed-manager``, ``MANAGER_PUBLIC_IP_ADDRESS`` has to be replaced by the
  public address of ``testbed-manager``

Change versions
===============

* Go to ``/opt/configuration`` on the manager node
* Run ``./scripts/set-openstack-version.sh yoga`` to set the OpenStack version to ``yoga``
* Run ``./scripts/set-ceph-version.sh pacific`` to set the Ceph version to ``pacific``
* Go to ``/home/dragon`` on the manager node
* Run ``ansible-playbook manager-part-2.yml`` to update the manager

This can also be achieved automatically by passing the wanted versions inside the environment
``ceph_version`` and ``openstack_version`` respectively.

.. _Deploy services:

Deploy services
===============

On the testbed, the services can currently be deployed manually. In the future, these manual
steps will be automated by Zuul CI.

* Basic Ceph services

  .. code-block:: console

     /opt/configuration/scripts/deploy/100-ceph-services-basic.sh

* Extended Ceph services (RGW + MDS)

  .. code-block:: console

     /opt/configuration/scripts/deploy/110-ceph-services-extended.sh

* Basic infrastructure services (MariaDB, RabbitMQ, Redis, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/200-infrastructure-services-basic.sh

* Extended infrastructure services (Patchman, phpMyAdmin, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/210-infrastructure-services-extended.sh

* Basic OpenStack services (Compute, Storage, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/300-openstack-services-basic.sh

* Extended OpenStack services (Telemetry, Kubernetes, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/310-openstack-services-extended.sh

* Baremetal OpenStack service

  .. code-block:: console

     /opt/configuration/scripts/deploy/320-openstack-services-baremetal.sh

* Additional OpenStack services (Rating, Container, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/330-openstack-services-additional.sh

* Monitoring services (Netdata, Prometheus exporters, ...)

  .. code-block:: console

     /opt/configuration/scripts/deploy/400-monitoring-services.sh

.. _Update services:

Update services
===============

* Ceph services

  .. code-block:: console

     /opt/configuration/scripts/upgrade/100-ceph-services.sh

* Basic infrastructure services (MariaDB, RabbitMQ, Redis, ...)

  .. code-block:: console

     /opt/configuration/scripts/upgrade/200-infrastructure-services-basic.sh

* Basic OpenStack services (Compute, Storage, ...)

  .. code-block:: console

     /opt/configuration/scripts/upgrade/300-openstack-services-basic.sh

* Baremetal OpenStack service

  .. code-block:: console

     /opt/configuration/scripts/upgrade/320-openstack-services-baremetal.sh

.. _Upgrade services:

Upgrade services
================

For an upgrade, the manager itself is updated first. Set the ``manager_version`` argument in
``environments/manager/configuration.yml`` to the new version and execute ``osism-update-manager``
afterwards.

The upgrade of the services is then done in the same way as the update of the services.
Simply re-run the scripts listed in :ref:`Update services`.

..note::

  When upgrading from a rolling release (``latest``, ``xena``, ..) to a stable release
  (``3.2.0``, ``4.0.0``, ..), it is important to remove the parameters ``ceph_version``
  and ``openstack_version`` from  ``environments/manager/configuration.yml``.
  For a stable release, the versions of Ceph and OpenStack to use are set by the version
  of the stable release (set via the ``manager_version`` parameter) and not by release names.

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
   docker compose down -v

Some services like phpMyAdmin or OpenStackClient will still run afterwards.

Webinterfaces
=============

.. note::
   All SSL enabled services within the testbed use certs which are signed by the self-signed
   `OSISM Testbed CA <https://raw.githubusercontent.com/osism/testbed/main/environments/kolla/certificates/ca/testbed.crt>`

.. raw:: html

   <table class="docutils align-default">
      <thead>
         <tr class="row-odd">
            <th class="head">Name</th>
            <th class="head">URL</th>
            <th class="head">Username</th>
            <th class="head">Password</th>
         </tr>
      </thead>
      <tbody>
         <tr class="row-even">
            <td>ARA</td>
            <td><a href="https://ara.testbed.osism.xyz/" target="_blank">https://ara.testbed.osism.xyz/</a></td>
            <td>ara</td>
            <td>password</td>
         </tr>
         <tr class="row-odd">
            <td>Ceph</td>
            <td><a href="https://api-int.testbed.osism.xyz:8140" target="_blank">https://api-int.testbed.osism.xyz:8140</a></td>
            <td>admin</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Flower</td>
            <td><a href="https://flower.testbed.osism.xyz/" target="_blank">https://flower.testbed.osism.xyz/</a></td>
            <td>-</td>
            <td>-</td>
         </tr>
         <tr class="row-odd">
            <td>Grafana</td>
            <td><a href="https://api-int.testbed.osism.xyz:3000" target="_blank">https://api-int.testbed.osism.xyz:3000</a></td>
            <td>admin</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Homer</td>
            <td><a href="https://homer.testbed.osism.xyz" target="_blank">https://homer.testbed.osism.xyz</a></td>
            <td>-</td>
            <td>-</td>
         </tr>
         <tr class="row-even">
            <td>Horizon (via Keystone)</td>
            <td><a href="https://api.testbed.osism.xyz" target="_blank">https://api.testbed.osism.xyz</a></td>
            <td>admin</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Horizon (via Keystone)</td>
            <td><a href="https://api.testbed.osism.xyz" target="_blank">https://api.testbed.osism.xyz</a></td>
            <td>test</td>
            <td>test</td>
         </tr>
         <tr class="row-even">
            <td>Horizon (via Keycloak)</td>
            <td><a href="https://api.testbed.osism.xyz" target="_blank">https://api.testbed.osism.xyz</a></td>
            <td>alice</td>
            <td>password</td>
         </tr>
         <tr class="row-odd">
            <td>Keycloak</td>
            <td><a href="https://keycloak.testbed.osism.xyz" target="_blank">https://keycloak.testbed.osism.xyz</a></td>
            <td>admin</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Kibana</td>
            <td><a href="https://api.testbed.osism.xyz:5601" target="_blank">https://api.testbed.osism.xyz:5601</a></td>
            <td>kibana</td>
            <td>password</td>
         </tr>
         <tr class="row-odd">
            <td>Netbox</td>
            <td><a href="https://netbox.testbed.osism.xyz/" target="_blank">https://netbox.testbed.osism.xyz/</a></td>
            <td>admin</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Netdata</td>
            <td><a href="https://testbed-manager.testbed.osism.xyz:19999" target="_blank">https://testbed-manager.testbed.osism.xyz:19999</a></td>
            <td>-</td>
            <td>-</td>
         </tr>
         <tr class="row-odd">
            <td>Patchman</td>
            <td><a href="https://patchman.testbed.osism.xyz/" target="_blank">https://patchman.testbed.osism.xyz/</a></td>
            <td>patchman</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>Prometheus</td>
            <td><a href="https://api-int.testbed.osism.xyz:9091/" target="_blank">https://api-int.testbed.osism.xyz:9091/</a></td>
            <td>-</td>
            <td>-</td>
         </tr>
         <tr class="row-odd">
            <td>phpMyAdmin</td>
            <td><a href="https://phpmyadmin.testbed.osism.xyz" target="_blank">https://phpmyadmin.testbed.osism.xyz</a></td>
            <td>root</td>
            <td>password</td>
         </tr>
         <tr class="row-even">
            <td>RabbitMQ</td>
            <td><a href="https://api-int.testbed.osism.xyz:15672/" target="_blank">https://api-int.testbed.osism.xyz:15672/</a></td>
            <td>openstack</td>
            <td>BO6yGAAq9eqA7IKqeBdtAEO7aJuNu4zfbhtnRo8Y</td>
         </tr>
      </tbody>
   </table>

.. note::

   To access the webinterfaces, make sure that you have a tunnel up and running for the
   internal networks.

   .. code-block:: console

      make sshuttle ENVIRONMENT=betacloud

.. note::

   If only the identity services were deployed, an error message (``You are not authorized to access this page``)
   appears after logging in to Horizon. This is not critical and results from the absence of the Nova service.

   .. figure:: /images/horizon-login-identity-testbed.png

ARA
---

.. figure:: /images/ara.png

Ceph
----

Deploy `Ceph` first.

.. code-block:: console

   osism apply bootstraph-ceph-dashboard

.. figure:: /images/ceph-dashboard.png

Grafana
-------

.. figure:: /images/grafana.png

Homer
-----

.. code-block:: console

   osism apply homer

.. figure:: /images/homer.png

Keycloak
--------

.. code-block:: console

   osism apply keycloak

.. figure:: /images/keycloak.png

Netbox
------

Netbox is part of the manager and does not need to be deployed individually.

.. figure:: /images/netbox.png

Netdata
-------

.. code-block:: console

   osism apply netdata

.. figure:: /images/netdata.png

Skydive
-------

Deploy `Clustered infrastructure services`, `Infrastructure services`, and
`Basic OpenStack services` first.

.. code-block:: console

   osism apply skydive

The Skydive agent creates a high load on the Open vSwitch services. Therefore
the agent is only started manually when needed.

.. code-block:: console

   osism apply manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent

.. figure:: /images/skydive.png

Patchman
--------

.. code-block:: console

   osism apply patchman-client
   osism apply patchman

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

   osism apply bootstrap-patchman

.. figure:: /images/patchman.png

Prometheus exporters
--------------------

Deploy `Clustered infrastructure services`, `Infrastructure services`, and
`Basic OpenStack services` first.

.. code-block:: console

   osism apply prometheus

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

   /opt/configuration/contrib/refstack/run.sh
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

     osism apply ceph-mons
     osism apply ceph-mgrs
     osism apply ceph-osds
     osism apply ceph-mdss
     osism apply ceph-crash
     osism apply ceph-rgws
     osism apply copy-ceph-keys
     osism apply cephclient

* Clustered infrastructure services

  .. code-block:: console

     osism apply common
     osism apply loadbalancer
     osism apply elasticsearch
     osism apply rabbitmq
     osism apply mariadb

* Infrastructure services (also deploy `Clustered infrastructure services`)

  .. code-block:: console

     osism apply openvswitch
     osism apply ovn
     osism apply memcached
     osism apply kibana


* Basic OpenStack services (also deploy `Infrastructure services`,
  `Clustered infrastructure services`, and `Ceph`)

  .. code-block:: console

     osism apply keystone
     osism apply horizon
     osism apply placement
     osism apply glance
     osism apply cinder
     osism apply neutron
     osism apply nova
     osism apply openstackclient
     osism apply bootstrap-basic

* Additional OpenStack services (also deploy `Basic OpenStack services` and all requirements)

  .. code-block:: console

     osism apply heat
     osism apply gnocchi
     osism apply ceilometer
     osism apply aodh
     osism apply barbican
     osism apply designate
     osism apply octavia
