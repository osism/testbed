# OSISM hyperconverged infrastructure (HCI) testbed

[![Build Status](https://travis-ci.org/osism/testbed.svg?branch=master)](https://travis-ci.org/osism/testbed)

Hyperconverged infrastructure (HCI) testbed based on OpenStack and Ceph, deployed by OSISM.

- [Overview](#overview)
- [Supported cloud providers](#supported-cloud-providers)
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

## Overview

By default the testbed consists of a manager and three HCI nodes, each with three block devices.
The manager serves as a central entry point into the environment.

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/overview.png)

## Supported cloud providers

* Betacloud
* Citycloud

## Notes

* **WARNING** The secrets are unencrypted in the individual files. **Therefore do not use the
  testbed publicly.**
* The configuration is intentionally kept quite static. Please no PRs to make the configuration
  more flexible/dynamic.
* The OSISM documentation uses hostnames, examples, addresses etc. from this testbed.
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

  ```
  devices:
    - /dev/sdb
    - /dev/sdc
  #  - /dev/sdd  # NOTE: the third volume is commented to be added later in tests
  ```
* The documentation of the OSISM can be found on https://docs.osism.de. There you will find
  further details on deployment, operation etc.

## Heat stack

The testbed is based on a Heat stack.

* ``stack.yml`` - stack with one manager node and three HCI nodes
* ``stack-single.yml`` - stack with only one manager node

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/stack-topology.png)

### Template

It is usually sufficient to use the prepared stacks. Changes to the template itself are normally
not necessary.

If you change the template of the Heat stack (``templates/stack.yml.j2``) you can update the
``stack.yml`` file with the ``jinja2-cli`` (https://github.com/mattrobenolt/jinja2-cli).

```
jinja2 -o stack.yml templates/stack.yml.j2
```

By default, the number of nodes is set to ``3``. The number can be adjusted via the parameter
``number_of_nodes``. When adding additional nodes (``number_of_nodes > 3``) to the stack, they
are not automatically added to the configuration.


```
jinja2 -o stack.yml -D number_of_nodes=6 templates/stack.yml.j2
```

To start only the manager ``number_of_nodes`` can be set to ``0``.

```
jinja2 -o stack-single.yml -D number_of_nodes=0 templates/stack.yml.j2
```

By default, the number of additional volumes is set to ``3``. The number can be adjusted via the parameter
``number_of_volumes``. When adding additional volumes (``number_of_volumes > 3``) to the stack, they
are not automatically added to the Ceph configuration.

```
jinja2 -o stack.yml -D number_of_volumes=4 templates/stack.yml.j2
```

## Network topology

![Network topology](https://raw.githubusercontent.com/osism/testbed/master/images/network-topology.png)

The networks ``net-to-public-testbed`` and ``net-to-betacloud-public`` are not part of the testbed.
They are standard networks on the Betacloud.

``public`` and ``betacloud`` are external networks on the Betacloud. These are also not part of the testbed.

### Networks

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

| Name             | CIDR                 | Description                                                                                              |
|------------------|----------------------|----------------------------------------------------------------------------------------------------------|
| out of band      | ``192.168.30.0/24``  | This network is not used in the testbed. It is available because there is usually always an OOB network. |
| management       | ``192.168.40.0/24``  | SSH access via this network.                                                                             |
| internal         | ``192.168.50.0/24``  | All internal communication, e.g. MariaDB and RabbitMQ, is done via this.                                 |
| storage frontend | ``192.168.70.0/24``  | For access of the compute nodes to the storage nodes.                                                    |
| storage backend  | ``192.168.80.0/24``  | For synchronization between storage nodes.                                                               |
| external         | ``192.168.90.0/24``  | Is used to emulate an external network.                                                                  |
| provider         | ``192.168.100.0/24`` | Is used to emulate an provider network.                                                                  |

### Nodes

The nodes always have the same postfix in the networks.

| Name             | CIDR                 |
|------------------|----------------------|
| testbed-manager  | ``192.168.X.5/24``   |
| testbed-node-1   | ``192.168.X.10/24``  |
| testbed-node-2   | ``192.168.X.11/24``  |
| testbed-node-3   | ``192.168.X.12/24``  |

### VIPs

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
* Ceilometer
* Cinder
* Glance
* Heat
* Horizon
* Keystone
* Neutron
* Nova
* Panko

## Preparations

* ``python-openstackclient`` must be installed
* Heat, the OpenStack orchestration service,  must be usable on the cloud environment
* a ``clouds.yml`` and ``secure.yml`` must be created (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)

## Configuration

The defaults for the stack parameters are intended for the Betacloud.

<table>
  <tr>
    <th>Parameter</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><code>availability_zone</code></td>
    <td><code>south-1</code></td>
  </tr>
  <tr>
    <td><code>flavor_controller</code></td>
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
    <td><code>public</code></td>
  </tr>
  <tr>
    <td><code>volume_size_storage</code></td>
    <td><code>10</code></td>
  </tr>
</table>

With the file ``environment.yml`` the parameters of the stack can be adjusted.
Further details on environments on https://docs.openstack.org/heat/latest/template_guide/environment.html.

```
---
parameters:
  availability_zone: south-1
  flavor_controller: 4C-16GB-40GB
  flavor_manager: 2C-4GB-20GB
  image: Ubuntu 18.04
  public: public
  volume_size_storage: 10
```

## Initialization

To start a testbed with one manager and three HCI nodes, ``stack.yml`` is used. To start
only a manager ``stack-single.yml`` is used.

Before building the stack it should be checked if it is possible to build it.

```
openstack --os-cloud testbed \
  stack create \
  --dry-run \
  -e environment.yml \
  -t stack.yml testbed
```

If the check is successful, the stack can be created.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  -t stack.yml testbed
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

Docker etc. are already installed during stack creation. Therefore the creation takes some time.

The manager is started after the deployment of the HCI nodes has been completed. This is necessary to
be able to carry out various preparatory steps after the manager has been made available.

After a change to the definition of a stack, the stack can be updated.

```
openstack --os-cloud testbed \
  stack update \
  -e environment.yml \
  -t stack.yml testbed
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

### Customisation

By default, no services are deployed when the stack is created. This is customizable.

The deployment of infrastructure services can be enabled via parameter ``deploy_infrastructure``.

Without the deployment of the infrastructure services the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  --parameter deploy_infrastructure=true \
  -t stack.yml testbed
```

The deployment of Ceph can be enabled via parameter ``deploy_ceph``.

Without the deployment of Ceph the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  --parameter deploy_ceph=true \
  -t stack.yml testbed
```

The deployment of OpenStack can be enabled via parameter ``deploy_openstack``.

The deployment of OpenStack depends on the deployment of Ceph and the infrastructure services.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  --parameter deploy_ceph=true \
  --parameter deploy_infrastructure=true \
  --parameter deploy_openstack=true \
  -t stack.yml testbed
```

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

* Access the manager

  ```
  ssh -i id_rsa.testbed dragon@$MANAGER_ADDRESS
  ```

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

## Deploy

* Infrastructure services

  ```
  /opt/configuration/scripts/deploy_infrastructure_services.sh
  ```

* Ceph services

  ```
  /opt/configuration/scripts/deploy_ceph_services.sh
  ```

* OpenStack services

  ```
  /opt/configuration/scripts/deploy_openstack_services.sh
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
  osism-ceph env-hci; osism-run custom fetch-ceph-keys; osism-infrastructure helper --tags cephclient
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
  osism-kolla deploy keystone,horizon,glance,cinder,neutron,nova
  ```

* Additional OpenStack services (also deploy `Basic OpenStack services` and all requirements)

  ```
  osism-kolla deploy heat,gnocchi,ceilometer,aodh,panko
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
| Horizon          | http://192.168.50.200      | admin    | TTgPSOSmgdmQAJUKu627DuzutgnIoAzsSxFg2ntu |
| Kibana           | http://192.168.50.200:5601 | kibana   | k2ReobFEsoxNm3DyZnkZmFPadSnCz6BjQhaLFoyB |
| Netdata          | http://192.168.50.5:19999  | -        | -                                        |
| phpMyAdmin       | http://192.168.40.5:8110   | root     | qNpdZmkKuUKBK3D5nZ08KMZ5MnYrGEe2hzH6XC0i |
| Skydive          | http://192.168.50.5:8085   | -        | -                                        |

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
