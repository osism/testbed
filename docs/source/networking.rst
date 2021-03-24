==========
Networking
==========

.. contents::
   :local:

.. figure:: /images/network-topology.png

The network ``net-to-external-testbed`` is not part of the testbed.
It is a standard network on the Betacloud. ``external`` is an external network on the Betacloud.
This network is also not part of the testbed.

Networks
========

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

================ ==================== ======================================================
Name             CIDR                 Description
================ ==================== ======================================================
out of band      ``192.168.0.0/20``   This network is not used in the testbed.
management       ``192.168.16.0/20``  SSH access via this network.
internal         ``192.168.32.0/20``  All internal communication, e.g. MariaDB and RabbitMQ.
wireguard        ``192.168.48.0/20``  Is used by Wireguard.
storage frontend ``192.168.64.0/20``  For access of the compute nodes to the storage nodes.
storage backend  ``192.168.80.0/20``  For synchronization between storage nodes.
external         ``192.168.96.0/20``  Is used to emulate an external network.
provider         ``192.168.112.0/20`` Is used to emulate an provider network.
================ ==================== ======================================================

Nodes
=====

The nodes always have the same postfix in the networks.

================ ==================
Name             CIDR
================ ==================
testbed-manager  ``192.168.X.5/20``
testbed-node-1   ``192.168.X.10/20``
testbed-node-2   ``192.168.X.11/20``
testbed-node-3   ``192.168.X.12/20``
================ ==================

VIPs
====

On the local workstation you should put the following entries into ``/etc/hosts``.
Without these entries e.g. the VNC access to instances does not work.

========= =================== =======================
Name      Address             Domain
========= =================== =======================
external  ``192.168.96.9``    ``api.osism.test``
internal  ``192.168.32.9``    ``api-int.osism.test``
========= =================== =======================
