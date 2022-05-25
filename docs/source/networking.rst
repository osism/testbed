==========
Networking
==========

Networks
========

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

================ ==================== ========================================================
Name             CIDR                 Description
================ ==================== ========================================================
management       ``192.168.16.0/20``  SSH access via this network & all internal communication
wireguard        ``192.168.48.0/20``  Is used by Wireguard.
provider         ``192.168.112.0/20`` Is used to emulate an provider network.
================ ==================== ========================================================

Warning: The provider network is set up with VXLAN tunneling between the nodes and can
currently only be used when OVN is being used as Neutron backend (this is the default). Trying
to switch to OVS will cause a conflict, since OVS will also try to use VXLAN as tunnel
mechanism. See https://github.com/osism/testbed/issues/1065 for details.

Nodes
=====

The nodes always have the same postfix in the networks.

================ ==================
Name             CIDR
================ ==================
testbed-manager  ``192.168.X.5/20``
testbed-node-Y   ``192.168.X.1Y/20``
================ ==================

VIPs
====

On the local workstation you should put the following entries into ``/etc/hosts``.
Without these entries e.g. the VNC access to instances does not work.

========= =================== =============================
Name      Address             Domain
========= =================== =============================
external  ``192.168.16.254``    ``api.testbed.osism.xyz``
internal  ``192.168.16.9``    ``api-int.testbed.osism.xyz``
========= =================== =============================
