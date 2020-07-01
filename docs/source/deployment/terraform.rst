=========
Terraform
=========

.. contents::
   :local:

The necessary files are located in the ``terraform`` directory.

Supported cloud providers
=========================

**Works**

There is a separate environment file, e.g. ``environment-Betacloud.tfvars``, for each supported cloud provider.

* `Betacloud <https://www.betacloud.de>`_
* `OVH <https://www.ovhcloud.com>`_

  .. note::

     * The public L3 network services at OVH are currently still in beta. For more details, please
       visit https://labs.ovh.com/public-cloud-l3-services.

     * The use of private networks must be explicitly activated at OVH. A so-called vRack is created for this purpose.

     * There is a problem with creating multiple networks at once on OVH. Therefore the creation of the networks must
       be started several times

       .. code-block:: none

          {"NeutronError": {"message": "Invalid input for operation: Can not get vracks for tenant xxx from DB!.", "type": "InvalidInput", "detail": ""}}

Preparations
============

* ``Terraform`` must be installed (https://learn.hashicorp.com/terraform/getting-started/install.html)
* a ``clouds.yaml`` and ``secure.yaml`` must be created (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml) (the file extension ``yaml`` is important)

Configuration
=============

The defaults for the environment parameters are intended for the Betacloud.

========================= ===========
**Parameter**             **Default**
------------------------- -----------
availability_zone         south-2
volume_availability_zone  south-2
network_availability_zone south-2
flavor_node               4C-16GB-40GB
flavor_manager            2C-4GB-20GB
image                     Ubuntu 18.04
public                    external
volume_size_storage       10
configuration_version     master
ceph_version              nautilus
openstack_version         train
========================= ===========

With the file ``environment.tfvars`` the parameters of the environment can be adjusted.

.. code-block:: none

   image = "OSISM base"
   flavor_node = "8C-32GB-40GB"

Initialization
==============

.. code-block:: console

   make dry-run

.. code-block:: console

   make create

.. code-block:: console

   make create ENVIRONMENT=environment-Betacloud.tfvars

.. code-block:: console

   make clean

Customisation
=============

By default, no services are deployed when the environment is created. This is customizable.

.. code-block:: console

   make deploy-infra ENVIRONMENT=environment-Betacloud.tfvars
   make deploy-ceph ENVIRONMENT=environment-Betacloud.tfvars
   make deploy-openstack ENVIRONMENT=environment-Betacloud.tfvars

Usage
=====

.. code-block:: console

   make console
   make ssh
   make sshuttle
