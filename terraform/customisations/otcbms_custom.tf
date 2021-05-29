provider "opentelekomcloud" {
  cloud = var.cloud_provider
}

resource "null_resource" "node_semaphore" {
  depends_on = [
    opentelekomcloud_compute_bms_server_v2.node_server,
    opentelekomcloud_compute_bms_server_v2.node_server_alt
  ]
}

resource "opentelekomcloud_compute_bms_server_v2" "node_server" {
  count             = 3
  name              = "${var.prefix}-node-${count.index}"
  availability_zone = var.availability_zone
  flavor_name       = var.flavor_node
  key_pair          = openstack_compute_keypair_v2.key.name
  image_id          = data.openstack_images_image_v2.image_node.id

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]

  network { port = openstack_networking_port_v2.node_port_management[count.index].id }

  user_data = <<-EOT
#cloud-config
network:
   config: disabled
package_update: false
package_upgrade: false
write_files:
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
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/cleanup.sh"
final_message: "The system is finally up, after $UPTIME seconds"
EOT
}

resource "opentelekomcloud_compute_bms_server_v2" "node_server_alt" {
  count             = "${var.number_of_nodes - 3}"
  name              = "${var.prefix}-node-${count.index + 3}"
  availability_zone = var.availability_zone
  flavor_name       = var.flavor_node_alt
  key_pair          = openstack_compute_keypair_v2.key.name
  image_id          = data.openstack_images_image_v2.image_node.id

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]

  network { port = openstack_networking_port_v2.node_port_management[count.index + 3].id }

  user_data = <<-EOT
#cloud-config
network:
   config: disabled
package_update: false
package_upgrade: false
write_files:
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
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
  - "rm -f /etc/network/interfaces.d/50-cloud-init.cfg"
  - "mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.unused"
  - "/root/node.sh"
  - "/root/cleanup.sh"
final_message: "The system is finally up, after $UPTIME seconds"
EOT
}
