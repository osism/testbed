=========
Overview
=========

.. contents::
   :local:

By default the testbed consists of a manager and three HCI nodes, each with three block devices.
The manager serves as a central entry point into the environment.

.. figure:: /images/overview.png

The virtual testbed provides an up-to-date, fully functional Ceph and OpenStack environment. It is
possible to evaluate workloads like Kubernetes on the basis of this virtual testbed.

.. figure:: /images/horizon.png

Supported releases
==================

The following stable Ceph and OpenStack releases are supported. The development branch
usually works too.

Ceph
----

The deployment of Ceph is based on `ceph-ansible <https://github.com/ceph/ceph-ansible>`_.

* Luminous
* Nautilus
* Octopus
* Pacific (**default**)
* Quincy

OpenStack
---------

The deployment of OpenStack is based on `kolla-ansible <https://opendev.org/openstack/kolla-ansible>`_.

* Rocky
* Stein
* Train
* Ussuri
* Victoria
* Wallaby
* Xena
* Yoga (**default**)

Software Bill Of Materials (SBOM)
=================================

The following services can currently be used with this testbed without further adjustments.
Feel free to open an issue on Github (https://github.com/osism/testbed/issues)  if you want
to use further services.

Infrastructure
--------------

* Ceph
* Elasticsearch
* Etcd
* Fluentd
* Gnocchi
* Grafana
* Haproxy
* Influxdb
* Keepalived
* Keycloak
* Kibana
* Mariadb
* Memcached
* Netbox
* Netdata
* Openvswitch
* Patchman
* Prometheus exporters
* Rabbitmq
* Redis
* Skydive

OpenStack
---------

* Aodh
* Barbican
* Ceilometer
* Cinder
* Glance
* Heat
* Horizon
* Ironic
* Keystone
* Manila
* Neutron
* Nova (with KVM)
* Octavia
* Panko
* Senlin
