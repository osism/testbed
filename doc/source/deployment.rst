==========
Deployment
==========

.. contents::
   :local:

.. note::

   With activated deployment of OpenStack only basic services
   (Compute, Storage, ..) are provided. Extended OpenStack services
   (Telemetry, Loadbalancer, Kubernetes, ..) and additional OpenStack
   services (Rating, Container, ..) can be added manually via scripts
   after deployment is complete.

.. note::

   The necessary files are located in the ``terraform`` directory.

Requirements for a physical environment
=======================================

Requirements for a virtual environment
======================================

Cloud resources
---------------

To use this testbed, a project on an OpenStack cloud environment is required. Cinder
must be usable there as additional service.

The testbed requires the following resources when using the default flavors.

* 1 keypair
* 6 security groups (50 security group rules)
* 6 networks with 6 subnetworks
* 1 router
* 30 ports
* 1 floating IP address
* 9 volumes (min 90 GB) plus 140GB root disks (depends on flavors)
* 4 instances (28 VCPUs, 104 GByte memory)

Virtual resources
-----------------

If the testbed is to be deployed independently of the Terraform integration with
OpenStack, the following resources are required.

Each system needs a root disk with at least 30 GByte storage.

2 networks are required. A network with which the virtual systems can be accessed
and via which the virtual systems can communicate with the outside world. In addition,
a fully internal network.

* 1 virtual system which is used as manager and monitoring node (4 VCPUs, 16 GByte memory)
* 3 virtual systems which are used as control, compute and, storage nodes (8 VCPUs, 32 GByte memory)
  * 3 additional volumes per virtual system with at least 10 GByte storage each

Ubuntu 20.04 is to be used as the base image for the virtual systems.

Software
--------

Terraform in a current version must be installed and usable on the local workstation.

Information on installing Terraform can be found in the Terraform
documentation: https://learn.hashicorp.com/tutorials/terraform/install-cli

Repository
----------

The code for deploying the testbed is hosted in a git repository, you need to make
a local copy of it by running:

.. code-block:: console

   mkdir -p ~/src/github.com/osism
   git clone https://github.com/osism/testbed ~/src/github.com/osism/testbed

Cloud access
------------

There is a separate environment file, e.g. ``environments/betacloud.tfvars``, for
each supported cloud provider.

The environment to be used is set via the ``ENVIRONMENT`` environment variable.

.. code-block:: console

   export ENVIRONMENT=betacloud

* `Betacloud <https://www.betacloud.de>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``betacloud``.

     * To use the Betacloud, please send an email to support@betacloud.de. Please state that you are
       interested in using the OSISM testbed.

* `Citycloud <https://www.citycloud.com>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``citycloud``.

     * Registration is possible at the following URL: https://admin.citycloud.com/login?register=true

* `OVH <https://www.ovhcloud.com>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``ovh``.

     * Registration is possible at the following URL: https://us.ovhcloud.com/auth/signup/#/

     * The public L3 network services at OVH are currently still in beta. For more details, please
       visit https://labs.ovh.com/public-cloud-l3-services.

     * The use of private networks must be explicitly activated at OVH. A so-called vRack is created for this purpose.

     * There is a problem with creating multiple networks at once on OVH. Therefore the creation of the networks must
       be started several times

       .. code-block:: json

          {"NeutronError": {"message": "Invalid input for operation: Can not get vracks for tenant xxx from DB!.", "type": "InvalidInput", "detail": ""}}

* `pluscloud open <https://www.plusserver.com/produkte/pluscloud-open>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``pluscloudopen``.

     * To use pluscloud open, you can call +49 2203 1045 3500, send an email to beratung@plusserver.com or arrange a call back https://www.plusserver.com/produkte/pluscloud-open

* `Open Telekom Cloud (OTC) <https://open-telekom-cloud.com/>`_

  .. note::

     * Registration is possible at the following URL: https://www.websso.t-systems.com/eshop/agb/de/public/configcart/show

* `SCS Demonstrator <https://ui.gx-scs.sovereignit.cloud/>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``gx-scs``.

* `Wavestack <https://www.wavestack.de/>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``wavestack``.


Preparations
============

* Clone required repositories

  .. code-block:: console

     mkdir -p ~/src/github.com/osism
     cd ~/src/github.com/osism
     git clone https://github.com/osism/testbed
     git clone https://github.com/osism/ansible-collection-commons
     git clone https://github.com/osism/ansible-collection-services

* `Terraform <https://www.terraform.io>`_ must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* `Ansible <https://www.ansible.com>`_ must be installed (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* ``clouds.yaml`` and ``secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml).
  If available, check that your openstack client tools work to validate the settings with
  e.g. ``openstack --os-cloud=the-name-of-the-entry availability zone list``.

  .. note::

     Note that terraform only supports public cloud profiles if a file named ``clouds-public.yaml``
     exists in one of the standard locations and contains the matching definition. The embedded
     well-known profiles that are available in the python openstack client do not work.
     TODO: Publish a clouds-public.yaml file for Betacloud (or all public clouds) and link
     it here.

  .. warning::

     The file extension ``yaml`` is important!

TLS certificates and hostnames
------------------------------

The testbed installation currently is hardcoded to use hostnames in the domain
``testbed.osism.xyz``.  This is a real domain and we provide the DNS records matching the addresses
used in the testbed, so that once you connect to your testbed via a direct link or e.g. wireguard,
you can access hosts and servers by their hostname like ``ssh testbed-manager.testbed.osism.xyz``.
You can find the playbook that generated these DNS records in ``contrib/ansible/dns.yaml``.

We also provide a wildcard TLS certificate signed by a custom CA for ``testbed.osism.xyz`` and
``*.testbed.osism.xyz`` (see ``contrib/ownca`` for details).

This CA is always used for each testbed. The CA is not regenerated and it is not planned to change
for the next 10 years.

In order for these certificates to be recognized locally as valid, this CA
(``environments/kolla/certificates/ca/testbed.crt``) must be made known locally.

If you want to replace this with your own certificate, have a look
at the example playbooks in the ``contrib/ownca`` folder.

In a future release we plan to make the used domain configurable.

Configuration
=============

The defaults for the environment variables are intended for the Betacloud.

========================= ===========
**Variable**              **Default**
------------------------- -----------
availability_zone         south-2
ceph_version              pacific
cloud_provider            betacloud
configuration_version     main
flavor_manager            SCS-4V:8:50
flavor_node               SCS-8V:32:50
image                     Ubuntu 20.04
network_availability_zone south-2
openstack_version         yoga
prefix                    testbed
public                    external
volume_availability_zone  south-2
volume_size_storage       10
========================= ===========

With the file ``environments/CLOUDPROVIDER.tfvars`` the parameters of the environment
``CLOUDPROVIDER`` can be adjusted.

.. code-block:: ini

   image             = "OSISM base"
   openstack_version = "yoga"

Beyond the terraform variables, you can enable special overrides by adding special
comments into the .tfvars files. The syntax is ``# override:XXXX``. This will
include the file ``overrides/XXXX_override.tf`` into the terraform deployment.

Currently two such overrides exist:

* ``neutron_availability_zone_hints``: This enables using network availability zone hints.
  betacloud and citycloud benefit from this.
* ``neutron_router_enable_snat``: This passes ``enable_snat: true`` for the router. This is
  required by OTC.

Via the variable ``prefix`` it is possible to change the name of the created resources. By default,
``testbed`` is used. With this variable it is possible to run several testbeds within one project.


Local Environment
=================

For local overrides ``local.env`` and ``environments/local.tfvars`` can be used. Remember to
also add a ``local`` entry to clouds.yaml.

.. code-block:: console

   cp environments/local.tfvars.sample environments/local.tfvars
   echo ENVIRONMENT=local >> local.env

Deployment
==========

Deployment is controlled via Ansible with the ``deploy.yml`` playbook.

The following command is executed from the ``testbed`` repository directory.
It creates the necessary infrastructure using Terraform and then deploys all
services using Ansible.

.. code-block:: console

   ansible-playbook playbooks/deploy.yml \
       -i ansible/localhost_inventory.yaml \
       -e cloud_env=$ENVIRONMENT \
       -e ansible_galaxy=ansible-galaxy \
       -e ansible_playbook=ansible-playbook

The ``Run part 3`` task takes some time to complete, depending on the cloud. Run times of
60-80 minutes are not unusual. Don't get impatient and have a coffee in the meantime.

.. note::

   Path to the ``ansible-galaxy`` binary or the ``ansible-playbook`` only needs to be
   adjusted if the binaries are not findable via ``PATH``.

Usage
=====

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


Checks
======

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


General Management
==================

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


Terraform Management
====================

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


Internals
=========

These are used for make internal functions and not supposed to be used by a user:

.. code-block:: console

   make .deploy.$(ENVIRONMENT)          # check if a deployment is present
   make .MANAGER_ADDRESS.$(ENVIRONMENT) # return manager address
   make .id_rsa.$(ENVIRONMENT)          # write private key


Decommissioning
===============

.. code-block:: console

   make clean ENVIRONMENT=betacloud

.. raw:: html
   :file: html/asciinema-tf-clean.html
