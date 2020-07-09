============
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
* 4 instances (16 VCPUs, 52 GByte memory)

.. note::

   When deploying all additional OpenStack services, the use of nodes with at least
   32 GByte memory is recommended. Then 100 GByte memory are required.
