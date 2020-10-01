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

Requirements
============

To use this testbed, a project on an OpenStack cloud environment is required. Cinder
must be usable there as additional service.

The testbed requires the following resources When using the default flavors.

* 1 keypair
* 6 security groups (50 security group rules)
* 6 networks with 6 subnetworks
* 1 router
* 30 ports
* 1 floating ip address
* 4 instances
* 9 volumes (min 90 GB) plus 140GB root disks (depends on flavors)
* 4 instances (18 VCPUs, 56 GByte memory)

.. note::

   When deploying all additional OpenStack services, the use of nodes with at least
   32 GByte memory is recommended. Then 104 GByte memory are required.

Supported cloud providers
=========================

**Works**

There is a separate environment file, e.g. ``environment-betacloud.tfvars``, for
each supported cloud provider.

* `Betacloud <https://www.betacloud.de>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``betacloud``.

* `Citycloud <https://www.citycloud.com>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``citycloud``.

* `OVH <https://www.ovhcloud.com>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``ovh``.

     * The public L3 network services at OVH are currently still in beta. For more details, please
       visit https://labs.ovh.com/public-cloud-l3-services.

     * The use of private networks must be explicitly activated at OVH. A so-called vRack is created for this purpose.

     * There is a problem with creating multiple networks at once on OVH. Therefore the creation of the networks must
       be started several times

       .. code-block:: json

          {"NeutronError": {"message": "Invalid input for operation: Can not get vracks for tenant xxx from DB!.", "type": "InvalidInput", "detail": ""}}

* `PlusServer <https://www.plusserver.com>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``pluscloudopen``.


Preparations
============

* `Terraform <https://www.terraform.io>`_ must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* ``clouds.yaml`` and ``secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)

  .. warning::

     The file extension ``yaml`` is important!

Configuration
=============

The defaults for the environment variables are intended for the Betacloud.

========================= ===========
**Variable**              **Default**
------------------------- -----------
availability_zone         south-2
ceph_version              nautilus
cloud_provider            betacloud
configuration_version     master
flavor_manager            2C-4GB-20GB
flavor_node               4C-16GB-40GB
image                     Ubuntu 18.04
network_availability_zone south-2
openstack_version         ussuri
public                    external
volume_availability_zone  south-2
volume_size_storage       10
========================= ===========

With the file ``environment-CLOUDPROVIDER.tfvars`` the parameters of the environment
``CLOUDPROVIDER`` can be adjusted.

.. code-block:: json

   image       = "OSISM base"
   flavor_node = "8C-32GB-40GB"

Initialization
==============

.. code-block:: console

   make dry-run ENVIRONMENT=betacloud

.. code-block:: console

   make deploy ENVIRONMENT=betacloud

.. raw:: html
   :file: html/asciinema-tf-deployment.html

.. code-block:: console

   make watch ENVIRONMENT=betacloud

.. note::

   By default, no additional services are deployed when the environment is
   created. The environment is only prepared and the manager is provided. This
   is customizable.

   * Use ``deploy-infra`` to deploy infrastructure services when building the environment.
   * Use ``deploy-ceph`` to deploy Ceph when building the environment.
   * Use ``deploy-openstack`` to deploy OpenStack when building the environment. This also
     includes Ceph and infrastructure services.

Usage
=====

.. code-block:: console

   make console ENVIRONMENT=betacloud
   make ssh ENVIRONMENT=betacloud
   make sshuttle ENVIRONMENT=betacloud

Decommissioning
===============

.. code-block:: console

   make clean ENVIRONMENT=betacloud

.. raw:: html
   :file: html/asciinema-tf-clean.html
