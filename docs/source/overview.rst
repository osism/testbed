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

* Luminous
* Nautilus (**default**)
* Octopus

OpenStack
---------

* Rocky
* Stein
* Train
* Ussuri
* Victoria (**default**)

Services
========

The following services can currently be used with this testbed without further adjustments.
Feel free to open an issue on Github (https://github.com/osism/testbed/issues)  if you want
to use further services.

Infrastructure
--------------

* AWX
* Ceph
* Cockpit
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
* Keystone
* Magnum
* Manila
* Neutron
* Nova (with KVM)
* Octavia
* Panko
