resource "openstack_networking_port_v2" "node_port_management" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_management.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_management.id]

  fixed_ip {
    ip_address = "192.168.16.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_port_v2" "node_port_internal" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_internal.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_internal.id]

  fixed_ip {
    ip_address = "192.168.32.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }

  allowed_address_pairs {
    ip_address = "192.168.32.9/32"
  }
}

resource "openstack_networking_port_v2" "node_port_external" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_external.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_external.id]

  fixed_ip {
    ip_address = "192.168.96.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_external.id
  }

  allowed_address_pairs {
    ip_address = "192.168.96.9/32"
  }
}

resource "openstack_networking_port_v2" "node_port_provider" {
  count      = var.number_of_nodes
  network_id = openstack_networking_network_v2.net_provider.id

  # NOTE: port_security_enabled not usable with OVH
  #
  # {"NeutronError": {"message": "Unrecognized attribute(s) 'port_security_enabled'", "type": "HTTPBadRequest", "detail": ""}}
  port_security_enabled = var.port_security_enabled

  fixed_ip {
    ip_address = "192.168.112.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}

resource "openstack_networking_port_v2" "node_port_storage_frontend" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_storage_frontend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_frontend.id]

  fixed_ip {
    ip_address = "192.168.64.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_frontend.id
  }
}

resource "openstack_networking_port_v2" "node_port_storage_backend" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_storage_backend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_backend.id]

  fixed_ip {
    ip_address = "192.168.80.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_backend.id
  }
}

resource "openstack_blockstorage_volume_v3" "node_volume" {
  count             = var.number_of_nodes * var.number_of_volumes
  name              = "${var.prefix}-volume-${count.index}-node-${count.index % var.number_of_nodes}"
  size              = var.volume_size_storage
  availability_zone = var.volume_availability_zone
}

resource "openstack_compute_volume_attach_v2" "node_volume_attachment" {
  count       = var.number_of_nodes * var.number_of_volumes
  instance_id = openstack_compute_instance_v2.node_server[count.index % var.number_of_nodes].id
  volume_id   = openstack_blockstorage_volume_v3.node_volume[count.index].id
}

resource "openstack_compute_instance_v2" "node_server" {
  count             = var.number_of_nodes
  name              = "${var.prefix}-node-${count.index}"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_node
  key_pair          = openstack_compute_keypair_v2.key.name
  config_drive      = true

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]

  network { port = openstack_networking_port_v2.node_port_management[count.index].id }
  network { port = openstack_networking_port_v2.node_port_internal[count.index].id }
  network { port = openstack_networking_port_v2.node_port_external[count.index].id }
  network { port = openstack_networking_port_v2.node_port_provider[count.index].id }
  network { port = openstack_networking_port_v2.node_port_storage_frontend[count.index].id }
  network { port = openstack_networking_port_v2.node_port_storage_backend[count.index].id }

  user_data = <<-EOT
#cloud-config
network:
   config: disabled
package_update: false
package_upgrade: false
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.node_port_internal[count.index].mac_address}": "${openstack_networking_port_v2.node_port_internal[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_external[count.index].mac_address}": "${openstack_networking_port_v2.node_port_external[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_provider[count.index].mac_address}": "${openstack_networking_port_v2.node_port_provider[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_storage_frontend[count.index].mac_address}": "${openstack_networking_port_v2.node_port_storage_frontend[count.index].all_fixed_ips[0]}",
          "${openstack_networking_port_v2.node_port_storage_backend[count.index].mac_address}": "${openstack_networking_port_v2.node_port_storage_backend[count.index].all_fixed_ips[0]}",
      }

      for interface in netifaces.interfaces():
          mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
          if mac_address in PORTS:
              subprocess.run("ip addr add %s/20 dev %s" % (PORTS[mac_address], interface), shell=True)
              subprocess.run("ip link set up dev %s" % interface, shell=True)
    path: /root/configure-network-devices.py
    permissions: '0600'
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: '0600'
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: '0600'
  - content: |
      ${indent(6, file("files/node.yml"))}
    path: /opt/node.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.yml"))}
    path: /opt/cleanup.yml
    permissions: '0644'
  - content: |
      ${indent(6, file("files/cleanup.sh"))}
    path: /root/cleanup.sh
    permissions: '0700'
  - content: |
      ${indent(6, file("files/node.sh"))}
    path: /root/node.sh
    permissions: '0700'
packages:
  - docker-ce-cli
  - docker-compose
runcmd:
  - "dpkg -r ansible || true"
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/cleanup.sh"
final_message: "The system is finally up, after $UPTIME seconds"
EOT
}
