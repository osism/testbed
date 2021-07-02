=====
Notes
=====

.. warning::

   The secrets are unencrypted in the individual files.

   **Therefore do not use the testbed publicly.**

.. note::

   The Keycloak private key stored in ``environments/custom/files/keycloak/private_key.pem``
   and the certificate stored in ``environments/custom/files/keycloak/cert.crt``,
   can be regenerated with the following commands:

   1) Generate the private key:

   .. code-block:: bash

      openssl genrsa -out private_key.pem 2048

   2) Generate a certificate signing request:

   .. code-block:: bash

      openssl req -new -key  private_key.pem -out  csr.csr

   3) Generate the certificate file:

   .. code-block:: bash

      openssl x509 -req -days 365 -in csr.csr -signkey  private_key.pem -out cert.crt


* The configuration is intentionally kept quite static. Please create no PRs to make the
  configuration more flexible/dynamic.
* The `OSISM documentation <https://docs.osism.tech>`_ uses hostnames, examples, addresses etc.
  from this testbed.
* Even if all components (storage, network, compute, control) are operated on the same nodes,
  there are separate networks. This is because in larger productive HCI environments, dedicated
  control nodes and network nodes are usually provided. It is also common to place storage
  frontend and storage backend on an independent/additional network infrastructure.
* The third volume (``/dev/sdd``) is not enabled for Ceph by default. This is to test the
  scaling of Ceph.
* Ansible errors that have something to do with undefined variables (e.g. AnsibleUndefined)
  are most likely due to cached facts that are no longer valid. The facts can be updated by
  running ``osism-generic facts``.

  To avoid this problem a cronjob should be used for regular updates: ``osism-run custom cronjobs``.
* The documentation of the OSISM can be found on https://docs.osism.tech. There you will find
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
