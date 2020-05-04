============
Requirements
============

To use this testbed, a project on an OpenStack cloud environment is required. Cinder and Heat
(when using the Heat stack template) must be usable there as additional services.

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
* 1 stack (when using the Heat stack template)
