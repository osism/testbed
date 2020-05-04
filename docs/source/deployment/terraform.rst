=========
Terraform
=========

.. contents::
   :local:

The necessary files are located in the ``terraform`` directory.

Supported cloud providers
=========================

**Works**

There is a separate environment file, e.g. ``environment-Betacloud.tfvars``, for each supported cloud provider.

* [Betacloud](https://www.betacloud.de)

Usage
=====

.. code-block:: console

   make deploy ENVIRONMENT=environment-Betacloud.tfvars
   make deploy-ceph ENVIRONMENT=environment-Betacloud.tfvars
   make deploy-openstack ENVIRONMENT=environment-Betacloud.tfvars
   make deploy-ceph ENVIRONMENT=environment-Betacloud.tfvars PARAMS="-var 'configuration_version=terraform'"

.. code-block:: console

   make console
   make ssh
   make sshuttle
   make clean
