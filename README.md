# OSISM testbed

[![Build Status](https://travis-ci.org/osism/testbed.svg?branch=master)](https://travis-ci.org/osism/testbed)
[![Documentation](https://img.shields.io/static/v1?label=&message=documentation&color=blue)](https://travis-ci.org/osism/testbed)

Hyperconverged infrastructure (HCI) testbed based on OpenStack and Ceph, deployed by [OSISM](https://www.osism.de).

- [Heat](#heat)

## Heat

The necessary files are located in the ``heat`` directory.

* ``stack.yml`` - stack with one manager node and three HCI nodes
* ``stack-single.yml`` - stack with only one manager node

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/stack-topology.png)

### Supported cloud providers

**Works**

There is a separate environment file, e.g. ``environment-Betacloud.yml``, for each supported cloud provider.

* [Betacloud](https://www.betacloud.de)
* [Citycloud](https://www.citycloud.com)

**Works with manual workarounds**

* [OTC](https://open-telekom-cloud.com/): Needs ``enable_snat``, ``enable_dhcp``, ``dns_nameservers``, and an older ``heat_template_version``. It also needs two cloud-init patches to get get userdata.

**Not working at the moment**

* [teuto.stack](https://teutostack.de/): Currently lacks support for Heat.

### Template

It is usually sufficient to use the prepared stacks. Changes to the template itself are normally
not necessary.

If you change the template of the Heat stack (``stack.yml.j2``) you can update the
``stack.yml`` file with the ``jinja2-cli`` (https://github.com/mattrobenolt/jinja2-cli).

```
jinja2 -o stack.yml stack.yml.j2
```

By default, the number of nodes is set to ``3``. The number can be adjusted via the parameter
``number_of_nodes``. When adding additional nodes (``number_of_nodes > 3``) to the stack, they
are not automatically added to the configuration.

The same with reduction of the number of nodes. When removing nodes (``number_of_nodes < 3``),
they are not automatically removed from the configuration.

The configuration is only tested with 3 nodes. With more or less nodes, the configuration must
be adjusted manually and problems may occur.

```
jinja2 -o stack.yml -D number_of_nodes=6 stack.yml.j2
```

To start only the manager ``number_of_nodes`` can be set to ``0``.

```
jinja2 -o stack-single.yml -D number_of_nodes=0 stack.yml.j2
```

By default, the number of additional volumes is set to ``3``. The number can be adjusted via the parameter
``number_of_volumes``. When adding additional volumes (``number_of_volumes > 3``) to the stack, they
are not automatically added to the Ceph configuration.

```
jinja2 -o stack.yml -D number_of_volumes=4 stack.yml.j2
```

The configuration is only tested with 3 volumes. With more or less volumes, the configuration must
be adjusted manually and problems may occur.

Using the included Makefile and calling ``make`` will recreate ``stack.yml`` and ``stack-single.yml``
using default parameters (3 nodes, 3 volumes each).

### Preparations

* ``python-openstackclient`` must be installed
* Heat, the OpenStack orchestration service,  must be usable on the cloud environment
* a ``clouds.yml`` and ``secure.yml`` must be created (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)
  or alternatively (not recommended) the old ``OS_`` environment setting style be used (via sourcing an appropriate ``openrc`` file).

### Configuration

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

With the file ``environment.yml`` the parameters of the stack can be adjusted.
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

### Initialization

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

If the check is successful, the stack can be created. ``make dry-run`` will do this 
invocation for you.

Note that you can set the ``export OS_CLOUD=testbed`` environment variable to avoid typing
``--os-cloud testbed`` repeatedly.

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

This can also be achieved using ``make clean`` or ``make clean-wait`` if you prefer watching
the cleanup process.

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

This can also be achieved using ``make deploy-infra``.

The deployment of Ceph can be enabled via parameter ``deploy_ceph``.

Without the deployment of Ceph the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  --parameter deploy_ceph=true \
  -t stack.yml testbed
```

This can also be achieved using ``make deploy-ceph``.

The deployment of OpenStack can be enabled via parameter ``deploy_openstack``.

The deployment of OpenStack depends on the deployment of Ceph and the infrastructure services.

```
openstack --os-cloud testbed \
  stack create \
  -e environment.yml \
  --parameter deploy_ceph=true \
  --parameter deploy_infrastructure=true \
  --parameter deploy_openstack=true \
  --timeout 150 \
  -t stack.yml testbed
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

### Usage

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
