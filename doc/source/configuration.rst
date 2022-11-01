=============
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
  betacloud and cleura benefit from this.
* ``neutron_router_enable_snat``: This passes ``enable_snat: true`` for the router. This is
  required by OTC.

Via the variable ``prefix`` it is possible to change the name of the created resources. By default,
``testbed`` is used. With this variable it is possible to run several testbeds within one project.


Local Environment
-----------------

For local overrides ``local.env`` and ``environments/local.tfvars`` can be used. Remember to
also add a ``local`` entry to clouds.yaml.

.. code-block:: console

   cp environments/local.tfvars.sample environments/local.tfvars
   echo ENVIRONMENT=local >> local.env
