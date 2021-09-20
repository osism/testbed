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

.. _Deploy services:

Deploy services
===============

On the testbed, the services can currently be deployed manually. In the future, these manual
steps will be automated by Zuul CI.

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

Update services
===============

The update of the services is done in the same way as the deployment of the services.
Simply re-run the scripts listed in :ref:`Deploy services`.

Upgrade services
================

For an upgrade, the manager itself is updated first. Set the ``manager_version`` argument in
``environments/manager/configuration.yml`` to the new version and execute ``osism-update-manager``
afterwards.

The upgrade of the services is then done in the same way as the deployment of the services.
Simply re-run the scripts listed in :ref:`Deploy services`.

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

Authentication with OpenID Connect
==================================

Authentication with OpenID Connect is possible via Keycloak,
which is automatically configured for OIDC mechanism when
the identity services are deployed with ``deploy-identity``.

Once the configuration is in place, the users
need to be provisioned into the LDAP database,
before they can be authenticated via OIDC.

SSL / TLS connection to Keycloak OpenID Connect provider
--------------------------------------------------------

Currently by default, the testbed does not use SSL / TLS
to secure the connection to Keycloak.
This poses security risks, and should only be used for demonstration
or test purposes, not in production.

Furthermore starting with
`8.0.2 <https://www.keycloak.org/docs/latest/release_notes/#keycloak-8-0-2>`_
Keycloak only sets, the ``SameSite`` parameter to ``None``
if SSL / TLS is in use.
Having Keycloak set ``SameSite=None`` is a must have for browsers,
that follow the IETF draft proposal titled `Incrementally Better Cookies
<https://datatracker.ietf.org/doc/html/draft-west-cookie-incrementalism-00>`_
which suggests to treat cookies without a SameSite attribute as ``SameSite=Lax``.

That treatment essentially disables the sending of the login cookies into
third party contexts, and in this case Keystone is considered a third party contex
from Keycloak, therfore the login via OpenID Connect won't work.

The Keycloak documentation also explicitly states,
that browsers with ``SameSite=Lax`` policy
only get full feature support if SSL / TLS is configured.
For further information see the the Keycloak documentation's
`Browsers with "SameSite=Lax by Default" Policy
<https://www.keycloak.org/docs/latest/securing_apps/
#browsers-with-samesite-lax-by-default-policy>`_  section.

Compatibility list of browsers, for accessing Keycloak without SSL / TLS:
-------------------------------------------------------------------------

Browsers enforcing ``SameSite=Lax``, which can't work:
------------------------------------------------------

Recent ``Chromium`` based browsers:

* Chromium 91 and newer version
* Vivalid 4.0 and newer version (Chrome/91.0.4472.79)
* Microsoft Edge 91 and newer version

Browsers, that can opt-out of enforcing ``SameSite=Lax``:
---------------------------------------------------------

Older ``Chromium`` based browsers, which can
disabling the ``SameSite by default cookies`` and ``Enable removing SameSite=None cookies``
flags in (`<chrome://flags>`_ and or `<vivaldi://flags>`_) and therfore can work:

* `Chromium 90 and earlier versions <https://www.chromium.org/getting-involved/download-chromium>`_
* `Vivalid 3.8 (Chrome/90.0.4430.214) and earlier versions <https://vivaldi.com/download/archive/>`_
* Microsoft Edge 90 and earlier version

Tested and recommended browsers, that are known to work well without further action:
------------------------------------------------------------------------------------

Gecko based browsers:

* Firefox 92
* SeaMonkey 2.53.9
* LibreWolf 91.0.2-1 (After continuing to the plain http site)

WebKit based browsers:

* Safari 14.1.2
* GnomeWeb 40.3

OpenStack web dashboard (Horizon) login via OpenID Connect
----------------------------------------------------------

For logging in via OIDC, open your browser at OpenStack Dashboard Login Page,
select ``Authenticate via Keycloak``, after being redirected to the Keycloak
login page, perform the login with the credentials provisioned into LDAP.
After that you will be redirected back to the Horizon dashboard, where
you will be logged in with your user.

OpenStack web dashboard (Horizon) logout
----------------------------------------

Keep in mind, that clicking ``Sign Out`` on the Horizon dashboard
currently doesn't revoke your OIDC token, and any consequent attempt
to ``Authenticate via Keycloak`` will succeed without providing the credentials.

The expiration time of the Single Sign On tokens can be
controlled on multiple levels in Keycloak.

1. On realm level under `Realm Settings` > `Tokes`.
   Assuming the `keycloak_realm` ansible variable is the default `osism`,
   and keycloak is listening on `http://192.168.16.5:8170`, then the
   configuration form is available here:
   http://192.168.16.5:8170/auth/admin/master/console/#/realms/osism/token-settings

   Detailed information is available in the
   Keycloak Server Administrator Documentation `Session and Token Timeouts
   <https://www.keycloak.org/docs/latest/server_admin/#_timeouts>`_ section.

2. In a realm down on the `client level
   <http://192.168.16.5:8170/auth/admin/master/console/#/realms/osism/clients>`_
   select the client (keystone), and under `Settings` > `Advanced Settings`.

   It is recommended to keep the `Access Token Lifespan` on a relatively low value,
   with the trend of blocking third party cookies.
   For further information see the Keycloak documentation's
   `Browsers with Blocked Third-Party Cookies
   <https://www.keycloak.org/docs/latest/securing_apps/
   #browsers-with-blocked-third-party-cookies>`_ section.


[TODO]
Proper logout.

OpenStack CLI operations with OpenID Connect password
-----------------------------------------------------

Using the openstack cli is also possible via OIDC,
assuming you provisioned the user ``testuser`` with password ``password``,
then you can perform a simple `project list` operation like this:

.. code-block:: console

   openstack \
     --os-auth-url http://192.168.16.12:5000/v3 \
     --os-auth-type v3oidcpassword \
     --os-client-id keystone \
     --os-client-secret 0056b89c-030f-486b-a6ad-f0fa398fa4ad \
     --os-username testuser \
     --os-password password \
     --os-identity-provider keycloak \
     --os-protocol openid \
     --os-identity-api-version 3 \
     --os-discovery-endpoint http://192.168.16.5:8170/auth/realms/osism/.well-known/openid-configuration \
   project list



OpenStack CLI token issue with OpenID Connect
---------------------------------------------

It is also possible to exchange your username/password to a token,
for further use with the cli.
The ``token issue`` subcommand returns an SQL table,
in which the `id` column's `value` field contains the token:

.. code-block:: console

   openstack \
     --os-auth-url http://192.168.16.12:5000/v3 \
     --os-auth-type v3oidcpassword \
     --os-client-id keystone \
     --os-client-secret 0056b89c-030f-486b-a6ad-f0fa398fa4ad \
     --os-username testuser \
     --os-password password \
     --os-identity-provider keycloak \
     --os-protocol openid \
     --os-identity-api-version 3 \
     --os-discovery-endpoint http://192.168.16.5:8170/auth/realms/osism/.well-known/openid-configuration \
     --os-openid-scope "openid profile email" \
   token issue \
       -c id
       -f value

An example token is like:

.. code-block:: console

   gAAAAABhC98gL8nsQWknro3JWDXWLFCG3CDr3Mi9OIlvVAZMjy2mNgYtlXv_0yAIy-
   nSlLAaLIGhht17-mwf8uclKgRuNVsYLSmgUpB163l89-ch2w2_OFe9zNSQNWf4qfd8
   Cl7E7XvvUoFr1N8Gh09vaYLvRvYgCGV05xBUSs76qCHa0qElPUsk56s5ft4ALrSrzD
   4cEQRVb5PXNjywdZk9_gtJziz31A7sD4LPIy82O5N9NryDoDw

OpenStack CLI operations with token
-----------------------------------

[TODO]

OpenStack CLI token revoke
--------------------------

[TODO]



Webinterfaces
=============

================ ========================== ======== ========================================
Name             URL                        Username Password
================ ========================== ======== ========================================
ARA              http://192.168.16.5:8120   ara      password
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
================ ========================== ======== ========================================

.. note::

   To access the webinterfaces, make sure that you have a tunnel up and running for the
   internal networks.

   .. code-block:: console

      make sshuttle ENVIRONMENT=betacloud

ARA
---

.. figure:: /images/ara.png

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
