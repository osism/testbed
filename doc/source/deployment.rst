==========
Deployment
==========

.. contents::
   :local:

.. note::

   With activated deployment of OpenStack only basic services
   (Compute, Storage, ..) are provided. Extended OpenStack services
   (Telemetry, Loadbalancer, Kubernetes, ..) and additional OpenStack
   services (Rating, Container, ..) can be added manually via scripts
   after deployment is complete.

Deployment is controlled via Ansible with the ``deploy.yml`` playbook.

The following command is executed from the ``testbed`` repository directory.
It creates the necessary infrastructure using Terraform and then deploys all
services using Ansible.

.. code-block:: console

   ansible-playbook playbooks/deploy.yml \
       -i ansible/localhost_inventory.yaml \
       -e cloud_env=$ENVIRONMENT \
       -e ansible_galaxy=ansible-galaxy \
       -e ansible_playbook=ansible-playbook

The ``Run part 3`` task takes some time to complete, depending on the cloud. Run times of
60-80 minutes are not unusual. Don't get impatient and have a coffee in the meantime.

.. note::

   Path to the ``ansible-galaxy`` binary or the ``ansible-playbook`` only needs to be
   adjusted if the binaries are not findable via ``PATH``.

.. note::

   Add ``-e manual_deploy=true`` if only the necessary infrastructure should be created.
   Other services such as OpenStack or Ceph are then not deployed and can be added
   manually afterwards.

Customise versions
==================

By default, the latest manager service, Ceph Pacific and OpenStack Yoga are deployed.
This can be customised via the parameters ``version_ceph``, ``version_manager``, and
``version_openstack``.

Deploy OpenStack in the ``xena`` version:

.. code-block:: console

   -e version_openstack=xena

Deploy Ceph in the ``quincy`` version:

.. code-block:: console

   -e version_ceph=quincy

Deploy the pre release ``4.0.0a`` of the stable release ``4.0.0``:

.. code-block:: console

   -e version_manager=4.0.0a

.. note::

   If a specific version of the manager and thus OSISM itself, a so-called stable release,
   is deployed, the explicit specification of the Ceph version and the OpenStack version
   is not possible. The versions of Ceph and OpenStack are then determined from the stable
   release of OSISM. For OSISM version 4.0.0, for example, this is Ceph Pacific and OpenStack
   Yoga.
