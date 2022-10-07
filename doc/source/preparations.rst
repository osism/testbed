============
Preparations
============

.. contents::
   :local:

* Clone required repositories

  .. code-block:: console

     mkdir -p ~/src/github.com/osism
     cd ~/src/github.com/osism
     git clone https://github.com/osism/testbed
     git clone https://github.com/osism/ansible-collection-commons
     git clone https://github.com/osism/ansible-collection-services

  .. note::

     The repositories can also be cloned to any other location.
     The path to the repositories is set via the parameter ``repo_path``.

* `Terraform <https://www.terraform.io>`_ must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* `Ansible <https://www.ansible.com>`_ must be installed (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* ``clouds.yaml`` and ``secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml).
  If available, check that your openstack client tools work to validate the settings with
  e.g. ``openstack --os-cloud=the-name-of-the-entry availability zone list``.

  .. note::

     Note that terraform only supports public cloud profiles if a file named ``clouds-public.yaml``
     exists in one of the standard locations and contains the matching definition. The embedded
     well-known profiles that are available in the python openstack client do not work.
     TODO: Publish a clouds-public.yaml file for Betacloud (or all public clouds) and link
     it here.

  .. warning::

     The file extension ``yaml`` is important!

TLS certificates and hostnames
------------------------------

The testbed installation currently is hardcoded to use hostnames in the domain
``testbed.osism.xyz``.  This is a real domain and we provide the DNS records matching the addresses
used in the testbed, so that once you connect to your testbed via a direct link or e.g. wireguard,
you can access hosts and servers by their hostname like ``ssh testbed-manager.testbed.osism.xyz``.
You can find the playbook that generated these DNS records in ``contrib/ansible/dns.yaml``.

We also provide a wildcard TLS certificate signed by a custom CA for ``testbed.osism.xyz`` and
``*.testbed.osism.xyz`` (see ``contrib/ownca`` for details).

This CA is always used for each testbed. The CA is not regenerated and it is not planned to change
for the next 10 years.

In order for these certificates to be recognized locally as valid, this CA
(``environments/kolla/certificates/ca/testbed.crt``) must be made known locally.

If you want to replace this with your own certificate, have a look
at the example playbooks in the ``contrib/ownca`` folder.

In a future release we plan to make the used domain configurable.
