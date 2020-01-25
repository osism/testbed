# OSISM hyperconverged infrastructure (HCI) testbed

[![Build Status](https://travis-ci.org/osism/testbed.svg?branch=master)](https://travis-ci.org/osism/testbed)

Hyperconverged infrastructure (HCI) testbed based on OpenStack and Ceph, deployed by OSISM.

- [Overview](#overview)
- [Notes](#notes)
- [Heat stack](#heat-stack)
- [Network topology](#network-topology)
- [Preparations](#preparations)
- [Initialization](#initialization)
- [Usage](#usage)
- [Purge](#purge)
- [Tools](#tools)
- [Todo](#todo)

## Overview

By default the testbed consists of a manager and three HCI nodes, each with three block devices.
The manager serves as a central entry point into the environment.

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/overview.png)

## Notes

* **WARNING** The secrets are unencrypted in the individual files. Therefore do not use the
  testbed publicly
* The configuration is intentionally kept quite static

## Heat stack

The testbed is based on a Heat stack. The stack is defined in the file ``stack.yml``.

![Stack topology](https://raw.githubusercontent.com/osism/testbed/master/images/stack-topology.png)

### Template

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

### Networks

With the exception of the manager, all nodes have a connection to any network. The manager
only has no connection to the storage backend.

| Name             | CIDR                 | Description |
|------------------|----------------------|-------------|
| management       | ``192.168.40.0/24``  |             |
| internal         | ``192.168.50.0/24``  |             |
| storage frontend | ``192.168.70.0/24``  |             |
| storage backend  | ``193.168.80.0/24``  |             |
| external         | ``192.168.90.0/24``  |             |
| provider         | ``192.168.100.0/24`` |             |

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

## Preparations

* ``python-openstackclient`` must be installed
* Heat, the OpenStack orchestration service,  must be usable on the cloud environment
* a ``clouds.yml`` and ``secure.yml`` must be created (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)

## Initialization

```
openstack --os-cloud testbed \
  stack create \
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

### Customisation

The deployment of OpenStack can be disabled via parameter ``deploy_openstack``.

```
openstack --os-cloud testbed \
  stack create \
  --parameter deploy_openstack=false \
  -t stack.yml testbed
```

The deployment of Ceph can be disabled via parameter ``deploy_ceph``. Without the deployment of
Ceph the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  --parameter deploy_ceph=false \
  -t stack.yml testbed
```

The deployment of infrastructure services can be disabled via parameter ``deploy_infrastructure``.
Without the deployment of the infrastructure services the deployment of OpenStack is not possible.

```
openstack --os-cloud testbed \
  stack create \
  --parameter deploy_infrastructure=false \
  -t stack.yml testbed
```

## Usage

* get private SSH key

  ```
  openstack --os-cloud testbed \
    stack output show \
    -f value \
    -c output_value \
    testbed private_key > id_rsa.testbed
  ```

* set permissions

  ```
  chmod 0600 id_rsa.testbed
  ```

* get the manager's address

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

* access the manager

  ```
  ssh -i id_rsa.testbed dragon@$MANAGER_ADDRESS
  ```

* use sshuttle (https://github.com/sshuttle/sshuttle) to access the individual
  services locally

  ```
  sshuttle \
    --ssh-cmd 'ssh -i id_rsa.testbed' \
    -r dragon@$MANAGER_ADDRESS \
    192.168.40.0/24 \
    192.168.50.0/24 \
    192.168.90.0/24
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
osism-ceph purge-docker-cluster
Are you sure you want to purge the cluster? Note that if with_pkg is not set docker packages and more will be uninstalled from non-atomic hosts. Do you want to continue?
 [no]: yes
```

### Manager services

```
cd /opt/manager
docker-compose down -v
```

Some services like phpMyAdmin or OpenStackClient will still run afterwards.

## Tools

### Random MySQL data

After deployment of MariaDB including HAProxy it is possible to create a test database with
four tables which are filled with randomly generated data. The script can be executed multiple
times to generate more data.

```
cd /opt/configuration/contrib
./mysql_random_data_load.sh NUMBER_OF_ROWS
```

## Todo

* set hostnames to node-0, node-1, node-2, manager (remove testbed prefix)
* use Heat resource groups
