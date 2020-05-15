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

Supported release
=================

The following stable releases are supported. The development branch usually works too.

* Ceph Luminous
* Ceph Nautilus
* Ceph Octopus
* OpenStack Rocky
* OpenStack Stein
* OpenStack Train

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
* Kibana
* Mariadb
* Memcached
* Netdata
* Openvswitch
* Prometheus
* Rabbitmq
* Redis
* Skydive

OpenStack
---------

* Aodh
* Barbican
* Ceilometer
* Cinder
* Cloudkitty
* Glance
* Heat
* Horizon
* Keystone
* Kuryr
* Magnum
* Manila
* Neutron
* Nova
* Octavia
* Panko
* Zun
