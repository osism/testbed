==========
Networking
==========

.. contents::
   :local:

.. figure:: /images/network-topology.png

The networks ``net-to-public-testbed`` and ``net-to-betacloud-public`` are not part of the testbed.
They are standard networks on the Betacloud.

``public`` and ``betacloud`` are external networks on the Betacloud. These are also not part of
the testbed.

Networks
========

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

================ ==================== ======================================================
Name             CIDR                 Description
================ ==================== ======================================================
out of band      ``192.168.30.0/24``  This network is not used in the testbed.
management       ``192.168.40.0/24``  SSH access via this network.
internal         ``192.168.50.0/24``  All internal communication, e.g. MariaDB and RabbitMQ.
wireguard        ``192.168.60.0/24``  Is used by Wireguard.
storage frontend ``192.168.70.0/24``  For access of the compute nodes to the storage nodes.
storage backend  ``192.168.80.0/24``  For synchronization between storage nodes.
external         ``192.168.90.0/24``  Is used to emulate an external network.
provider         ``192.168.100.0/24`` Is used to emulate an provider network.
octavia          ``192.168.110.0/24`` Internal Octavia management network.
================ ==================== ======================================================

Nodes
=====

The nodes always have the same postfix in the networks.

================ ==================
Name             CIDR
================ ==================
testbed-manager  ``192.168.X.5/24``
testbed-node-1   ``192.168.X.10/24``
testbed-node-2   ``192.168.X.11/24``
testbed-node-3   ``192.168.X.12/24``
================ ==================

VIPs
====

On the local workstation you should put the following entries into ``/etc/hosts``.
Without these entries e.g. the VNC access to instances does not work.

========= =================== =======================
Name      Address             Domain
========= =================== =======================
external  ``192.168.90.200``  ``api.osism.local``
internal  ``192.168.50.200``  ``api-int.osism.local``
========= =================== =======================
