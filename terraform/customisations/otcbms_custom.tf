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
package_update: true
package_upgrade: true
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
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
package_update: true
package_upgrade: true
write_files:
runcmd:
  - "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
final_message: "The system is finally up, after $UPTIME seconds"
EOT
}
