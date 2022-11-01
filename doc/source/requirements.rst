============
Requirements
============

.. contents::
   :local:


Infrastructure resources
========================

For an environment on a cloud
-----------------------------

To use this testbed, a project on an OpenStack cloud environment is required.

The testbed requires the following virtual resources when using the default flavors.

* 1 keypair
* 6 security groups (50 security group rules)
* 6 networks with 6 subnetworks
* 1 router
* 30 ports
* 1 floating IP address
* 9 volumes (min 90 GB) plus 140GB root disks (depends on flavors)
* 4 instances (with 28 VCPUs and 104 GByte memory in total)

.. note::

   If the cloud you are using does not offer a block storage service (Cinder),
   you can work with Ephemeral Volumes from the compute service (Nova).

For an environment on physical hardware
---------------------------------------

For an environment on a hypervisor
----------------------------------

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
========

* ``make`` must be installed on the system

Ansible
-------

Ansible in a current version must be installed and usable on the local workstation.

Currently Ansible 6.x is supported.

Information on installing Ansible can be found in the Ansible
documentation: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

Terraform
---------

Terraform in a current version must be installed and usable on the local workstation.

Currently Terraform 1.2.x is supported.

Information on installing Terraform can be found in the Terraform
documentation: https://learn.hashicorp.com/tutorials/terraform/install-cli


This repository
===============

The code for deploying the testbed is hosted in a git repository, you need to make
a local copy of it by running:

.. code-block:: console

   mkdir -p ~/src/github.com/osism
   git clone https://github.com/osism/testbed ~/src/github.com/osism/testbed

.. note::

   The repository can also be cloned to any other location. The path to this repository
   is set via the parameter ``basepath``.


Cloud access
============

.. note::

   The necessary files are located in the ``terraform`` directory.

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

* `Cleura <https://cleura.com/>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``cleura``.

     * Registration is possible at the following URL: https://cleura.cloud/login

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

* `Fuga Cloud <https://fuga.cloud>`_

  .. note::

     * The credentials are stored in ``clouds.yaml`` and ``secure.yaml`` with the name ``fuga``.
     * Per project, 50 GBytes of memory are available by default. Therefore, the flavor ``t3.small``
       is used by default. If you have increased the quota via support it is better to use the flavor
       ``t3.medium`` for the nodes.
     * You have to use application credentials: https://my.fuga.cloud/account/application-credentials

       .. code-block:: yaml

          ---
          clouds:
            fuga:
              auth:
                auth_url: https://core.fuga.cloud:5000/v3
                application_credential_id: "ID"
                application_credential_secret: "SECRET"
              interface: public
              identity_api_version: 3
              auth_type: "v3applicationcredential"
