resource "null_resource" "node_semaphore" {
  depends_on = [
    openstack_compute_instance_v2.node_server
  ]
}

resource "openstack_compute_instance_v2" "node_server" {
  count             = var.number_of_nodes
  name              = "${var.prefix}-node-${count.index}"
  availability_zone = var.availability_zone
  flavor_name       = var.flavor_node
  key_pair          = openstack_compute_keypair_v2.key.name
  config_drive      = var.enable_config_drive

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

resource "openstack_compute_volume_attach_v2" "node_volume_attachment" {
  count       = var.number_of_nodes * var.number_of_volumes
  instance_id = openstack_compute_instance_v2.node_server[count.index % var.number_of_nodes].id
  volume_id   = openstack_blockstorage_volume_v3.node_volume[count.index].id
}

resource "openstack_blockstorage_volume_v3" "node_volume" {
  count             = var.number_of_nodes * var.number_of_volumes
  name              = "${var.prefix}-volume-${count.index}-node-${count.index % var.number_of_nodes}"
  size              = var.volume_size_storage
  availability_zone = var.volume_availability_zone
}
