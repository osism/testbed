# OSISM hyperconverged infrastructure (HCI) testbed

[![Build Status](https://travis-ci.org/osism/testbed.svg?branch=master)](https://travis-ci.org/osism/testbed)

Hyperconverged infrastructure (HCI) testbed based on OpenStack and Ceph, deployed by [OSISM](https://www.osism.de).

- [Overview](#overview)
- [Supported releases](#supported-releases)
- [Supported cloud providers](#supported-cloud-providers)
- [Requirements](#requirements)
- [Notes](#notes)
- [Heat stack](#heat-stack)
- [Network topology](#network-topology)
- [Services](#services)
- [Preparations](#preparations)
- [Configuration](#configuration)
- [Initialization](#initialization)
- [Usage](#usage)
- [Purge](#purge)
- [Tools](#tools)
- [Recipes](#recipes)
- [Webinterfaces](#webinterfaces)
- [Refstack](#refstack)

## Overview

By default the testbed consists of a manager and three HCI nodes, each with three block devices.
The manager serves as a central entry point into the environment.

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/overview.png)

The virtual testbed provides an up-to-date, fully functional Ceph and OpenStack environment. It is
possible to evaluate workloads like Kubernetes on the basis of this virtual testbed.

![Horizon screenshot](https://raw.githubusercontent.com/osism/testbed/master/images/horizon.png)

## Supported releases

The following stable releases are supported. The development branch usually works too.

* Ceph Luminous
* Ceph Nautilus
* Ceph Octopus
* OpenStack Rocky
* OpenStack Stein
* OpenStack Train

## Supported cloud providers

**Works**

There is a separate environment file, e.g. ``heat/environment-Betacloud.yml``, for each supported cloud provider.

* [Betacloud](https://www.betacloud.de)
* [Citycloud](https://www.citycloud.com)

**Works with manual workarounds**

* [OTC](https://open-telekom-cloud.com/): Needs ``enable_snat``, ``enable_dhcp``, ``dns_nameservers``, and an older ``heat_template_version``. It also needs two cloud-init patches to get get userdata.

**Not working at the moment**

* [teuto.stack](https://teutostack.de/): Currently lacks support for Heat.

## Requirements

To use this testbed, a project on an OpenStack cloud environment is required. Cinder and Heat
must be usable there as additional services.

The testbed requires the following resources When using the default flavors.

* 1 keypair
* 6 security groups (50 security group rules)
* 6 networks with 6 subnetworks
* 1 router
* 30 ports
* 1 floating ip address
* 4 instances
* 9 volumes (min 90 GB) plus 140GB root disks (depends on flavors)
* 4 instances (16 VCPUs, 52 GByte memory)
* 1 stack

## Notes

* **WARNING** The secrets are unencrypted in the individual files. **Therefore do not use the
  testbed publicly.**
* The configuration is intentionally kept quite static. Please no PRs to make the configuration
  more flexible/dynamic.
* The [OSISM documentation](https://docs.osism.de) uses hostnames, examples, addresses etc.
  from this testbed.
* Even if all components (storage, network, compute, control) are operated on the same nodes,
  there are separate networks. This is because in larger productive HCI environments, dedicated
  control nodes and network nodes are usually provided. It is also common to place storage
  frontend and storage backend on an independent/additional network infrastructure.
* The third node (``testbed-node-2``) is not enabled for services by default. This is to
  test the scaling of the services.

  ```
  # NOTE: The node testbed-node-2 is commented to be able to test scaling
  #       in the testbed.
  # testbed-node-2.osism.local
  ```
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
* To speed up the Ansible playbooks, [ARA](https://ara.recordsansible.org) can be disabled. This
  is done by executing ``/opt/configuration/scripts/disable-ara.sh``. Afterwards no more logs are
  available in the ARA web interface.
* There is a prepared OpenStack base image. This will create the testbed a bit faster. On the
  Betacloud this image is available as ``OSISM base``. It is used as default in the
  ``heat/environment-Betacloud.yml`` environment file. Further details can be found in the repository
  [osism/testbed-image](https://github.com/osism/testbed-image).

## Heat stack

The testbed is based on a Heat stack.

* ``heat/stack.yml`` - stack with one manager node and three HCI nodes
* ``heat/stack-single.yml`` - stack with only one manager node

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/stack-topology.png)

### Template

It is usually sufficient to use the prepared stacks. Changes to the template itself are normally
not necessary.

If you change the template of the Heat stack (``heat/templates/stack.yml.j2``) you can update the
``heat/stack.yml`` file with the ``jinja2-cli`` (https://github.com/mattrobenolt/jinja2-cli).

```
jinja2 -o stack.yml heat/templates/stack.yml.j2
```

By default, the number of nodes is set to ``3``. The number can be adjusted via the parameter
``number_of_nodes``. When adding additional nodes (``number_of_nodes > 3``) to the stack, they
are not automatically added to the configuration.

The same with reduction of the number of nodes. When removing nodes (``number_of_nodes < 3``),
they are not automatically removed from the configuration.

The configuration is only tested with 3 nodes. With more or less nodes, the configuration must
be adjusted manually and problems may occur.

```
jinja2 -o heat/stack.yml -D number_of_nodes=6 heat/templates/stack.yml.j2
```

To start only the manager ``number_of_nodes`` can be set to ``0``.

```
jinja2 -o heat/stack-single.yml -D number_of_nodes=0 heat/templates/stack.yml.j2
```

By default, the number of additional volumes is set to ``3``. The number can be adjusted via the parameter
``number_of_volumes``. When adding additional volumes (``number_of_volumes > 3``) to the stack, they
are not automatically added to the Ceph configuration.

```
jinja2 -o heat/stack.yml -D number_of_volumes=4 heat/templates/stack.yml.j2
```

The configuration is only tested with 3 volumes. With more or less volumes, the configuration must
be adjusted manually and problems may occur.

Using the included Makefile and calling
```
make
```
will recreate ```heat/stack.yml``` and ```heat/stack-single.yml``` using default parameters (3 nodes, 3 volumes each).

## Network topology

![Network topology](https://raw.githubusercontent.com/osism/testbed/master/images/network-topology.png)

The networks ``net-to-public-testbed`` and ``net-to-betacloud-public`` are not part of the testbed.
They are standard networks on the Betacloud.

``public`` and ``betacloud`` are external networks on the Betacloud. These are also not part of the testbed.

### Networks

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

| Name             | CIDR                 | Description                                                                                       |
|------------------|----------------------|---------------------------------------------------------------------------------------------------|
| out of band      | ``192.168.30.0/24``  | This network is not used in the testbed. It is available because there is usually an OOB network. |
| management       | ``192.168.40.0/24``  | SSH access via this network.                                                                      |
| internal         | ``192.168.50.0/24``  | All internal communication, e.g. MariaDB and RabbitMQ, is done via this.                          |
| storage frontend | ``192.168.70.0/24``  | For access of the compute nodes to the storage nodes.                                             |
| storage backend  | ``192.168.80.0/24``  | For synchronization between storage nodes.                                                        |
| external         | ``192.168.90.0/24``  | Is used to emulate an external network.                                                           |
| provider         | ``192.168.100.0/24`` | Is used to emulate an provider network.                                                           |
| octavia          | ``192.168.110.0/24`` | Internal Octavia management network.                                                              |

### Nodes

The nodes always have the same postfix in the networks.

| Name             | CIDR                 |
|------------------|----------------------|
| testbed-manager  | ``192.168.X.5/24``   |
| testbed-node-1   | ``192.168.X.10/24``  |
| testbed-node-2   | ``192.168.X.11/24``  |
| testbed-node-3   | ``192.168.X.12/24``  |

### VIPs

On the local workstation you should put the following entries into ``/etc/hosts``.
Without these entries e.g. the VNC access to instances does not work.

| Name             | Address                  | Domain                  |
|------------------|--------------------------|-------------------------|
| external         | ``192.168.90.200``       | ``api.osism.local``     |
| internal         | ``192.168.50.200``       | ``api-int.osism.local`` |

## Services

The following services can currently be used with this testbed without further adjustments.
Feel free to open an issue on Github (https://github.com/osism/testbed/issues)  if you want
to use further services.

### Infrastructure

* Ceph
* Cockpit
* Elasticsearch
* Etcd
* Fluentd
* Gnocchi
* Grafana
* Haproxy
* Keepalived
* Kibana
* Mariadb
* Memcached
* Netdata
* Openvswitch
* Rabbitmq
* Redis
* Skydive

### OpenStack

* Aodh
* Barbican
* Ceilometer
* Cinder
* Cloudkitty
* Glance
* Heat
* Horizon
* Keystone
* Magnum
* Neutron
* Nova
* Octavia
* Panko

## Preparations

* ``python-openstackclient`` must be installed
* Heat, the OpenStack orchestration service,  must be usable on the cloud environment
* a ``clouds.yml`` and ``secure.yml`` must be created (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml) or alternatively (not recommended) the old ``OS_`` environment setting style be used (via sourcing an appropriate ``openrc`` file).

## Configuration

The defaults for the stack parameters are intended for the Betacloud.

<table>
  <tr>
    <th>Parameter</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><code>availability_zone</code></td>
    <td><code>south-2</code></td>
  </tr>
  <tr>
    <td><code>volume_availability_zone</code></td>
    <td><code>south-2</code></td>
  </tr>
  <tr>
    <td><code>network_availability_zone</code></td>
    <td><code>south-2</code></td>
  </tr>
  <tr>
    <td><code>flavor_node</code></td>
    <td><code>4C-16GB-40GB</code></td>
  </tr>
  <tr>
    <td><code>flavor_manager</code></td>
    <td><code>2C-4GB-20GB</code></td>
  </tr>
  <tr>
    <td><code>image</code></td>
    <td><code>Ubuntu 18.04</code></td>
  </tr>
  <tr>
    <td><code>public</code></td>
    <td><code>external</code></td>
  </tr>
  <tr>
    <td><code>volume_size_storage</code></td>
    <td><code>10</code></td>
  </tr>
    <td><code>configuration_version</code></td>
    <td><code>master</code></td>
  </tr>
  </tr>
    <td><code>ceph_version</code></td>
    <td><code>nautilus</code></td>
  </tr>
  <tr>
    <td><code>openstack_version</code></td>
    <td><code>train</code></td>
  </tr>
</table>

With the file ``heat/environment.yml`` the parameters of the stack can be adjusted.
Further details on environments on https://docs.openstack.org/heat/latest/template_guide/environment.html.

```
---
parameters:
  availability_zone: south-2
  volume_availability_zone: south-2
  network_availability_zone: south-2
  flavor_node: 4C-16GB-40GB
  flavor_manager: 2C-4GB-20GB
  image: Ubuntu 18.04
  public: external
  volume_size_storage: 10
  ceph_version: nautilus
  openstack_version: train
  configuration_version: master
```

## Initialization

To start a testbed with one manager and three HCI nodes, ``heat/stack.yml`` is used. To start
only a manager ``heat/stack-single.yml`` is used.

Before building the stack it should be checked if it is possible to build it.

```
openstack --os-cloud testbed \
  stack create \
  --dry-run \
  -e heat/environment.yml \
  -t heat/stack.yml testbed
```

If the check is successful, the stack can be created. ``make dry-run`` will do this 
invocation for you.

Note that you can set the ``export OS_CLOUD=testbed`` environment variable to avoid typing
``--os-cloud testbed`` repeatedly.

```
openstack --os-cloud testbed \
  stack create \
  -e heat/environment.yml \
  -t heat/stack.yml testbed
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| id                  | 97107041-afa6-46be-9ba7-51a92bbea5a1 |
| stack_name          | testbed                              |
| description         | No description                       |
| creation_time       | 2019-11-24T15:36:06Z                 |
| updated_time        | None                                 |
| stack_status        | CREATE_IN_PROGRESS                   |
| stack_status_reason | Stack CREATE started                 |
+---------------------+--------------------------------------+
```

This can also be achieved using ``make create``. (If you are using a cloud name different from
``testbed`` and you have not done an export OS_CLOUD, you can override the default by passing
``make create OS_CLOUD=yourcloudname``.)

The environment file to be used can be specified via the parameter ``ENVIRONMENT``.

Docker etc. are already installed during stack creation. Therefore the creation takes some time.
You can use ``make watch`` to watch the installation proceeding.

The manager is started after the deployment of the HCI nodes has been completed. This is necessary to
be able to carry out various preparatory steps after the manager has been made available.

After a change to the definition of a stack, the stack can be updated.

```
openstack --os-cloud testbed \
  stack update \
  -e heat/environment.yml \
  -t heat/stack.yml testbed
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| id                  | 2317ea11-f5c8-454e-9595-a7f0e14eaae6 |
| stack_name          | testbed                              |
| description         | No description                       |
| creation_time       | 2020-02-09T19:41:54Z                 |
| updated_time        | 2020-02-11T21:34:45Z                 |
| stack_status        | UPDATE_IN_PROGRESS                   |
| stack_status_reason | Stack UPDATE started                 |
+---------------------+--------------------------------------+
```

If the stack is no longer needed it can be deleted.

```
openstack --os-cloud testbed \
  stack delete testbed
Are you sure you want to delete this stack(s) [y/N]? y
```

This can also be achieved using ``make clean`` or ``make clean-wait`` if you prefer watching
the cleanup process.

### Customisation

By default, no services are deployed when the stack is created. This is customizable.

The deployment of infrastructure services can be enabled via parameter ``deploy_infrastructure``.

Without the deployment of the infrastructure services the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  -e heat/environment.yml \
  --parameter deploy_infrastructure=true \
  -t heat/stack.yml testbed
```

This can also be achieved using ``make deploy-infra``.

The deployment of Ceph can be enabled via parameter ``deploy_ceph``.

Without the deployment of Ceph the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  -e heat/environment.yml \
  --parameter deploy_ceph=true \
  -t heat/stack.yml testbed
```

This can also be achieved using ``make deploy-ceph``.

The deployment of OpenStack can be enabled via parameter ``deploy_openstack``.

The deployment of OpenStack depends on the deployment of Ceph and the infrastructure services.

```
openstack --os-cloud testbed \
  stack create \
  -e heat/environment.yml \
  --parameter deploy_ceph=true \
  --parameter deploy_infrastructure=true \
  --parameter deploy_openstack=true \
  --timeout 150 \
  -t heat/stack.yml testbed
```

The ``--timeout 150`` parameter tells heat to wait up to 2.5hrs for
completion.
(The default timeout for heat stacks is typically 60mins, which will only be enough under
ideal conditions for the complete stack.)

This can also be achieved using ``make deploy-openstack``.

The parameters ``ceph_version`` and ``openstack_version`` change the deployed versions of
Ceph and OpenStack respectively from their defaults ``nautilus`` and ``train``.

For Ceph, ``luminous`` and ``octopus`` can be used, for OpenStack, we can also test ``rocky``
and ``stein``. It should be noted that the defaults are tested best.

## Usage

* Get private SSH key

  ```
  openstack --os-cloud testbed \
    stack output show \
    -f value \
    -c output_value \
    testbed private_key > id_rsa.testbed
  ```

* Set permissions

  ```
  chmod 0600 id_rsa.testbed
  ```

  Both steps can be done using ``make ~/.ssh/id_rsa.testbed``.

* Get the manager's address

  ```
  openstack --os-cloud testbed \
    stack output show \
    testbed manager_address
  +--------------+----------------------+
  | Field        | Value                |
  +--------------+----------------------+
  | description  | No description given |
  | output_key   | manager_address      |
  | output_value | MANAGER_ADDRESS      |
  +--------------+----------------------+
  ```

  ```
  MANAGER_ADDRESS=$(openstack --os-cloud testbed \
    stack output show \
    -c output_value \
    -f value \
    testbed manager_address)
  ```

  ``make .MANAGER_ADDRESS.testbed`` outputs the IP address and creates a
  sourcable file ``.MANAGER_ADDRESS.testbed``.

* Access the manager

  ```
  ssh -i id_rsa.testbed dragon@$MANAGER_ADDRESS
  ```

  There is a shortcut ``make ssh`` available.

* Use sshuttle (https://github.com/sshuttle/sshuttle) to access the individual
  services locally

  ```
  sshuttle \
    --ssh-cmd 'ssh -i id_rsa.testbed' \
    -r dragon@$MANAGER_ADDRESS \
    192.168.40.0/24 \
    192.168.50.0/24 \
    192.168.90.0/24
  ```

### Change versions

* Go to ``/opt/configuration`` on the manager node
* Run ``./scripts/set-openstack-version.sh stein`` to set the OpenStack version to ``stein``
* Run ``./scripts/set-ceph-version.sh nautilus`` to set the Ceph version to ``nautilus``
* Go to ``/home/dragon`` on the manager node
* Run ``ansible-playbook manager-part-2.yml`` to update the manager

This can also be achieved automatically by passing the wanted versions inside the environment
``ceph_version`` and ``openstack_version`` respectively.

## Deploy

* Infrastructure services

  ```
  /opt/configuration/scripts/deploy_infrastructure_services.sh
  ```

* Ceph services

  ```
  /opt/configuration/scripts/deploy_ceph_services.sh
  ```

* Basic OpenStack services

  ```
  /opt/configuration/scripts/deploy_openstack_services_basic.sh
  ```

* Additional OpenStack services

  ```
  /opt/configuration/scripts/deploy_openstack_services_additional.sh
  ```

## Purge

These commands completely remove parts of the environment. This makes reuse possible
without having to create a completely new environment.

### OpenStack & infrastructure services

```
osism-kolla _ purge
Are you sure you want to purge the kolla environment? [no]: yes
Are you really sure you want to purge the kolla environment? [no]: ireallyreallymeanit
```

### Ceph

```
find /opt/configuration -name 'ceph*keyring' -exec rm {} \;
osism-ceph purge-docker-cluster
Are you sure you want to purge the cluster? Note that if with_pkg is not set docker
packages and more will be uninstalled from non-atomic hosts. Do you want to continue?
 [no]: yes
```

### Manager services

```
cd /opt/manager
docker-compose down -v
```

Some services like phpMyAdmin or OpenStackClient will still run afterwards.

## Tools

### Random data

The contrib directory contains some scripts to fill the components of the environment with random data.
This is intended to generate a realistic data load, e.g. for upgrades or scaling tests.

#### MySQL

After deployment of MariaDB including HAProxy it is possible to create four test databases each with
four tables which are filled with randomly generated data. The script can be executed multiple
times to generate more data.

```
cd /opt/configuration/contrib
./mysql_random_data_load.sh 100000
```

#### Elasticsearch

After deployment of Elasticsearch including HAProxy it is possible to create 14 test indices
which are filled with randomly generated data. The script can be executed multiple times to
generate more data.

14 indices are generated because the default retention time for the number of retained
indices is set to 14.

```
cd /opt/configuration/contrib
./elasticsearch_random_data_load.sh 100000
```

### Check infrastructure services

The contrib directory contains a script to check the clustered infrastructure services. The
configuration is so that two nodes are already sufficient.

```
cd /opt/configuration/contrib
./check_infrastructure_services.sh
Elasticsearch   OK - elasticsearch (kolla_logging) is running. status: green; timed_out: false; number_of_nodes: 2; ...

MariaDB         OK: number of NODES = 2 (wsrep_cluster_size)

RabbitMQ        RABBITMQ_CLUSTER OK - nb_running_node OK (2) nb_running_disc_node OK (2) nb_running_ram_node OK (0)

Redis           TCP OK - 0.002 second response time on 192.168.50.10 port 6379|time=0.001901s;;;0.000000;10.000000
```

## Recipes

This section describes how individual parts of the testbed can be deployed.

* Ceph

  ```
  osism-ceph testbed
  osism-run custom fetch-ceph-keys
  osism-infrastructure helper --tags cephclient
  ```

* Clustered infrastructure services

  ```
  osism-kolla deploy common,haproxy,elasticsearch,rabbitmq,mariadb,redis
  ```

* Infrastructure services (also deploy `Clustered infrastructure services`)

  ```
  osism-kolla deploy openvswitch,memcached,etcd,kibana
  ```

* Basic OpenStack services (also deploy `Infrastructure services`, `Clustered infrastructure services`, and `Ceph`)

  ```
  osism-kolla deploy keystone,horizon,placement,glance,cinder,neutron,nova
  osism-infrastructure helper --tags openstackclient
  osism-custom run bootstrap-basic
  ```

* Additional OpenStack services (also deploy `Basic OpenStack services` and all requirements)

  ```
  osism-kolla deploy heat,gnocchi,ceilometer,aodh,panko,magnum,barbican,designate
  ```

* Network analyzer (also deploy `Clustered infrastructure services`, `Infrastructure services`, and `Basic OpenStack services`)

  ```
  osism-kolla deploy skydive
  ```

  The Skydive agent creates a high load on the Open vSwitch services. Therefore the agent is only
  started manually when needed.

  ```
  osism-generic manage-container -e container_action=stop -e container_name=skydive_agent -l skydive-agent
  ```

* Realtime monitoring

  ```
  osism-infrastructure netdata
  ```

  ![Netdata webinterface](https://raw.githubusercontent.com/osism/testbed/master/images/netdata.png)

* Cockpit

  ```
  osism-generic cockpit
  osism-run custom generate-ssh-known-hosts
  ```

  ![Cockpit webinterface](https://raw.githubusercontent.com/osism/testbed/master/images/cockpit.png)

## Webinterfaces

| Name             | URL                        | Username | Password                                 |
|------------------|----------------------------|----------|------------------------------------------|
| ARA              | http://192.168.40.5:8120   | ara      | S6JE2yJUwvraiX57                         |
| Cockpit          | https://192.168.40.5:8130  | dragon   | da5pahthaew2Pai2                         |
| Horizon          | http://192.168.50.200      | admin    | pYV8bV749aDMXLPlYJwoJs4ouRPWezCIOXYAQP6v |
| Kibana           | http://192.168.50.200:5601 | kibana   | k2ReobFEsoxNm3DyZnkZmFPadSnCz6BjQhaLFoyB |
| Netdata          | http://192.168.50.5:19999  | -        | -                                        |
| phpMyAdmin       | http://192.168.40.5:8110   | root     | qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i |
| Skydive          | http://192.168.50.5:8085   | -        | -                                        |

## Refstack

```
/opt/configuration/contrib/refstack/refstack.sh
[...]
======
Totals
======
Ran: 285 tests in 1306.4010 sec.
 - Passed: 283
 - Skipped: 2
 - Expected Fail: 0
 - Unexpected Success: 0
 - Failed: 0
Sum of execute time for each test: 1027.4324 sec.
```

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Author information

This testbed was created by [Betacloud Solutions GmbH](https://www.betacloud-solutions.de).
