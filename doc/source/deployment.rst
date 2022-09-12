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
