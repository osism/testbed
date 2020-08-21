resource "openstack_networking_floatingip_v2" "manager_floating_ip" {
  pool       = var.public
  port_id    = openstack_networking_port_v2.manager_port_management.id
  depends_on = [openstack_networking_router_interface_v2.router_interface]
}

resource "openstack_networking_port_v2" "manager_port_management" {
  network_id = openstack_networking_network_v2.net_management.id
  security_group_ids = [
    openstack_compute_secgroup_v2.security_group_management.id,
    openstack_compute_secgroup_v2.security_group_manager.id
  ]

  fixed_ip {
    ip_address = "192.168.40.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }
}

resource "openstack_networking_port_v2" "manager_port_internal" {
  network_id         = openstack_networking_network_v2.net_internal.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_internal.id]

  fixed_ip {
    ip_address = "192.168.50.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_internal.id
  }

  allowed_address_pairs {
    ip_address = "192.168.60.0/24"
  }
}

resource "openstack_networking_port_v2" "manager_port_external" {
  network_id         = openstack_networking_network_v2.net_external.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_external.id]

  fixed_ip {
    ip_address = "192.168.90.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_external.id
  }

  allowed_address_pairs {
    ip_address = "192.168.60.0/24"
  }
}

resource "openstack_networking_port_v2" "manager_port_provider" {
  network_id = openstack_networking_network_v2.net_provider.id

  # NOTE: port_security_enabled not usable with OVH
  #
  # {"NeutronError": {"message": "Unrecognized attribute(s) 'port_security_enabled'", "type": "HTTPBadRequest", "detail": ""}}
  port_security_enabled = var.port_security_enabled

  fixed_ip {
    ip_address = "192.168.100.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_provider.id
  }
}

resource "openstack_networking_port_v2" "manager_port_storage_frontend" {
  network_id         = openstack_networking_network_v2.net_storage_frontend.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_storage_frontend.id]

  fixed_ip {
    ip_address = "192.168.70.5"
    subnet_id  = openstack_networking_subnet_v2.subnet_storage_frontend.id
  }
}

resource "openstack_compute_instance_v2" "manager_server" {
  name              = "${var.prefix}-manager"
  availability_zone = var.availability_zone
  image_name        = var.image
  flavor_name       = var.flavor_manager
  key_pair          = openstack_compute_keypair_v2.key.name

  depends_on = [
    openstack_compute_instance_v2.node_server
  ]

  network { port = openstack_networking_port_v2.manager_port_management.id }
  network { port = openstack_networking_port_v2.manager_port_internal.id }
  network { port = openstack_networking_port_v2.manager_port_external.id }
  network { port = openstack_networking_port_v2.manager_port_provider.id }
  network { port = openstack_networking_port_v2.manager_port_storage_frontend.id }

  user_data = <<-EOT
#cloud-config
package_update: true
package_upgrade: false
packages:
  - ifupdown
write_files:
  - content: |
      import subprocess
      import netifaces

      PORTS = {
          "${openstack_networking_port_v2.manager_port_internal.mac_address}": "${openstack_networking_port_v2.manager_port_internal.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_external.mac_address}": "${openstack_networking_port_v2.manager_port_external.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_provider.mac_address}": "${openstack_networking_port_v2.manager_port_provider.all_fixed_ips[0]}",
          "${openstack_networking_port_v2.manager_port_storage_frontend.mac_address}": "${openstack_networking_port_v2.manager_port_storage_frontend.all_fixed_ips[0]}",
      }

      for interface in netifaces.interfaces():
          mac_address = netifaces.ifaddresses(interface)[netifaces.AF_LINK][0]['addr']
          if mac_address in PORTS:
              subprocess.run("ip addr add %s/24 dev %s" % (PORTS[mac_address], interface), shell=True)
              subprocess.run("ip link set up dev %s" % interface, shell=True)
    path: /root/configure-network-devices.py
    permissions: 0600
  - content: ${openstack_compute_keypair_v2.key.public_key}
    path: /home/ubuntu/.ssh/id_rsa.pub
    permissions: 0600
  - content: |
      ${indent(6, openstack_compute_keypair_v2.key.private_key)}
    path: /home/ubuntu/.ssh/id_rsa
    permissions: 0600
  - content: |
      ${indent(6, file("files/node.yml"))}
    path: /opt/node.yml
    permissions: 0644
  - content: |
      ${indent(6, file("files/cleanup.yml"))}
    path: /opt/cleanup.yml
    permissions: 0644
  - content: |
      ${indent(6, file("files/manager-part-1.yml"))}
    path: /opt/manager-part-1.yml
    permissions: 0644
  - content: |
      ${indent(6, file("files/manager-part-2.yml"))}
    path: /opt/manager-part-2.yml
    permissions: 0644
  - content: |
      ${indent(6, file("files/manager-part-3.yml"))}
    path: /opt/manager-part-3.yml
    permissions: 0644
  - content: |
      ${indent(6, file("files/node.sh"))}
    path: /root/node.sh
    permissions: 0700
  - content: |
      ${indent(6, file("files/manager.sh"))}
    path: /root/manager.sh
    permissions: 0700
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/manager.sh"
final_message: "The system is finally up, after $UPTIME seconds"
power_state:
  mode: reboot
  condition: True
EOT

}
