=====
Notes
=====

.. warning::

   The secrets are unencrypted in the individual files.

   **Therefore do not use the testbed publicly.**

* The configuration is intentionally kept quite static. Please no PRs to make the configuration
  more flexible/dynamic.
* The `OSISM documentation <https://docs.osism.de>`_ uses hostnames, examples, addresses etc.
  from this testbed.
* Even if all components (storage, network, compute, control) are operated on the same nodes,
  there are separate networks. This is because in larger productive HCI environments, dedicated
  control nodes and network nodes are usually provided. It is also common to place storage
  frontend and storage backend on an independent/additional network infrastructure.
* The third node (``testbed-node-2``) is not enabled for services by default. This is to
  test the scaling of the services.

  .. code-block:: ini

     # NOTE: The node testbed-node-2 is commented to be able to test scaling
     #       in the testbed.
     # testbed-node-2.osism.test

* The third volume (``/dev/sdd``) is not enabled for Ceph by default. This is to test the
  scaling of Ceph.
* Ansible errors that have something to do with undefined variables (e.g. AnsibleUndefined)
  are most likely due to cached facts that are no longer valid. The facts can be updated by
  running ``osism-generic facts``.

  To avoid this problem a cronjob should be used for regular updates: ``osism-run custom cronjobs``.
* The documentation of the OSISM can be found on https://docs.osism.de. There you will find
  further details on deployment, operation etc.
* The manager is used as pull through cache for Docker images and Ubuntu packages. This reduces
  the amount of traffic consumed.
* To speed up the Ansible playbooks, `ARA <https://ara.recordsansible.org>`_ can be disabled. This
  is done by executing ``/opt/configuration/scripts/disable-ara.sh``. Afterwards no more logs are
  available in the ARA web interface.
* There is a prepared OpenStack base image. This will create the testbed a bit faster. On the
  Betacloud this image is available as ``OSISM base``. It is used as default in the
  Betacloud environment files. Further details can be found in the repository
  `osism/testbed-image <https://github.com/osism/testbed-image>`_.
