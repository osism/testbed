resource "openstack_networking_port_v2" "node_port_management" {
  count              = var.number_of_nodes
  network_id         = openstack_networking_network_v2.net_management.id
  security_group_ids = [openstack_compute_secgroup_v2.security_group_management.id]

  fixed_ip {
    ip_address = "192.168.16.1${count.index}"
    subnet_id  = openstack_networking_subnet_v2.subnet_management.id
  }

  allowed_address_pairs {
    ip_address = "192.168.16.9/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.16.254/20"
  }

  allowed_address_pairs {
    ip_address = "192.168.112.0/20"
  }
}

resource "openstack_blockstorage_volume_v3" "node_base_volume" {
  image_id          = data.openstack_images_image_v2.image_node.id
  count             = 0
  name              = "${var.prefix}-volume-${count.index}-node-base"
  size              = var.volume_size_base
  availability_zone = var.volume_availability_zone
  volume_type       = var.volume_type
}
